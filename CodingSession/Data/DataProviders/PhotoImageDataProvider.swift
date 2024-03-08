//
//  PhotoImageDataProvider.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import Combine
import Photos
import UIKit

final class PhotoImageDataProvider: ImageDataProvider {
    var assets: [PHAsset] = []
    
    private var systemPhotoManager: PHImageManager {
        PHImageManager.default()
    }
    
    func loadAssets() async throws {
        let access = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        
        guard access == .authorized else {
            throw ImageDataProviderError.notAuthorized
        }
                
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var videoAssets: [PHAsset] = []
           
        fetchResult.enumerateObjects { (asset, _, _) in
            videoAssets.append(asset)
        }
        
        assets = videoAssets
    }
    
    func requestImage(_ asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let requestOptions = PHImageRequestOptions()
        
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        return systemPhotoManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { (image, _) in
            resultHandler(image)
        }
    }
    
    func cancelLoading(requestId: PHImageRequestID) {
        systemPhotoManager.cancelImageRequest(requestId)
    }
}

