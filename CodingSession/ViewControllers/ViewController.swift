//
//  ViewController.swift
//  CodingSession
//
//  Created by Pavel Ilin on 01.11.2023.
//

import Accelerate
import SnapKit
import Photos
import UIKit

final class ViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private lazy var dataProvider: ImageDataProvider = PhotoImageDataProvider()
    private var targetSize: CGSize = .init(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
    private var loadingTask: Task<Void, Never>?
    
    private lazy var dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        collectionView.register(ViewControllerCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if loadingTask == nil { // Initial load
            loadingTask = Task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        loadingTask?.cancel()
        do {
            try await dataProvider.loadAssets()
            await refreshUI()
        } catch {
            handleError(error)
        }
    }
    
    private func refreshUI() async {
        collectionView.reloadData()
    }
    
    private func handleError(_ error: Error) {
        let alert = UIAlertController(title: String(localized: "Failed to load data", comment: "Failed to load data"),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized:"OK", comment: "OK"), style: .cancel))
        present(alert, animated: true)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(with: ViewControllerCell.self, for: indexPath)
        
        let asset = dataProvider.assets[indexPath.row]
           
        _ = dataProvider.requestImage(asset, size: targetSize) { image in
            DispatchQueue.main.async {
                cell.thumbImageView.image = image
            }
        }
        
        cell.durationLabel.text = dateFormatter.string(from: asset.duration)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataProvider.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        targetSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}
