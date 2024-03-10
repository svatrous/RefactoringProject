//
//  PhotoViewModel.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import Combine
import Photos
import UIKit

final class PhotoViewModel {
    
    private var disposables: Set<AnyCancellable> = .init()
    private lazy var dataProvider: ImageDataProvider = PhotoImageDataProvider()
    private var loadingTask: Task<Void, Never>?
    var items: CurrentValueSubject<[PHAsset], Never> = .init([])
    var error: PassthroughSubject<Error, Never> = .init()
    var loading: CurrentValueSubject<Bool, Never> = .init(false)
    var hasAccess: CurrentValueSubject<Bool, Never> = .init(false)
    
    func grantAccess() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await dataProvider.grantAccess()
                
                Task { @MainActor [weak self] in
                    self?.hasAccess.value = true
                    self?.subscribeToChanges()
                }
            } catch {
                Task { @MainActor [weak self] in
                    self?.error.send(error)
                }
            }
        }
    }
    
    func loadData() {
        loadingTask?.cancel()
        
        loading.value = true
        loadingTask = Task { [weak self] in
            guard let self else { return }
            let result = await dataProvider.loadAssets()
            
            Task { @MainActor [weak self] in
                self?.items.value = result
                self?.loading.value = false
            }
        }
    }
    
    func requestImage(_ asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        dataProvider.requestImage(asset, size: size, resultHandler: resultHandler)
    }
}

private extension PhotoViewModel {
    func subscribeToChanges() {
        dataProvider
            .dataChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.loadData()
            }
            .store(in: &disposables)
    }
}
