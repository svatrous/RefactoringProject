//
//  ViewController.swift
//  CodingSession
//
//  Created by Pavel Ilin on 01.11.2023.
//

import UIKit
import RxSwift
import SnapKit
import Accelerate
import Photos

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var collectionView: UICollectionView!
    
    var assets: [PHAsset] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: ViewControllerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewControllerCell", for: indexPath) as! ViewControllerCell
        
        let asset = self.assets[indexPath.row]
        
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
        return self.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

class ViewControllerCell: UICollectionViewCell {
    
    var thumbImageView: UIImageView!
    var durationLabel: UILabel!
    
    var image: UIImage! {
        didSet {
            thumbImageView.image = image
        }
    }
    
    var title: String! {
        didSet {
            durationLabel.text = title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        thumbImageView = UIImageView(frame: .zero)
        contentView.addSubview(thumbImageView)
        thumbImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        
        durationLabel = UILabel(frame: .zero)
        contentView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(8)
            make.bottom.equalTo(-8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
