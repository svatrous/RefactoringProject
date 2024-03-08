//
//  ViewController.swift
//  CodingSession
//
//  Created by Pavel Ilin on 01.11.2023.
//

import Accelerate
import SnapKit
import Photos
import RxSwift
import UIKit

final class ViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    var assets: [PHAsset] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        collectionView.register(ViewControllerCell.self, forCellWithReuseIdentifier: "ViewControllerCell")
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var videoAssets: [PHAsset] = []
           
        fetchResult.enumerateObjects { (asset, _, _) in
            videoAssets.append(asset)
        }
        
        assets = videoAssets
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: ViewControllerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewControllerCell", for: indexPath) as! ViewControllerCell
        
        let asset = assets[indexPath.row]
        
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)  // Размер изображения. Вы можете установить другой размер, если нужно меньшее разрешение для превью.
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, _) in
            cell.image = image
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        
        cell.title = formatter.string(from: asset.duration)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
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
