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
    private var loadingImageDict: [ViewControllerCell: Task<UIImage?, Error>] = [:]
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
    
    @MainActor
    func loadImage(for cell: ViewControllerCell, asset: PHAsset, size: CGSize) async throws -> UIImage? {
        loadingImageDict[cell]?.cancel()
        let task: Task<UIImage?, Error> = Task { [weak self] in
            guard let self else { return nil }
            
            try Task.checkCancellation()
            let image = await loadAssetImage(asset, size: size)
            try Task.checkCancellation()
            return image
        }
        
        loadingImageDict[cell] = task
        return try await task.value
    }
    
    private func loadAssetImage(_ asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(with: .success(nil))
                return
            }
            
            _ = requestImage(asset, size: size) { image in
                continuation.resume(with: .success(image))
            }
        }
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
