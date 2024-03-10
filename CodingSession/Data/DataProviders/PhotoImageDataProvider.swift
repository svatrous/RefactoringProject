//
//  PhotoImageDataProvider.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import Combine
import Photos
import UIKit

private actor ResultActor {
    var fetchResult: PHFetchResult<PHAsset>?
    
    func saveResult(_ result: PHFetchResult<PHAsset>) {
        fetchResult = result
    }
}

final class PhotoImageDataProvider: NSObject, ImageDataProvider {
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    var dataChanged: PassthroughSubject<Void, Never> = .init()
    
    private var systemPhotoManager: PHImageManager {
        PHImageManager.default()
    }
    
    private lazy var actor: ResultActor = .init()
    
    func grantAccess() async throws {
        let access = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        
        guard access == .authorized || access == .limited else {
            throw ImageDataProviderError.notAuthorized
        }
    }
    
    func loadAssets() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        //        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let result = PHAsset.fetchAssets(with: fetchOptions)
        
        var videoAssets: [PHAsset] = Array(repeating: PHAsset(), count: result.count)
        result.enumerateObjects { (asset, index, _) in
            videoAssets[index] = asset
        }
        
        await actor.saveResult(result)
        return videoAssets
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

extension PhotoImageDataProvider: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task {
            await handleLibraryChange(changeInstance)
        }
    }
    
    private func handleLibraryChange(_ changeInstance: PHChange) async {
        guard let fetchResult = await actor.fetchResult,
              let changeDetails = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        
        // Check if there were real changes. For example let's track that count was changes (could happen in case of Limited access to the library)
        let hasChanges = changeDetails.hasIncrementalChanges ||
        changeDetails.hasMoves ||
        changeDetails.fetchResultBeforeChanges.count != changeDetails.fetchResultAfterChanges.count
        
        await actor.saveResult(changeDetails.fetchResultAfterChanges)
        
        if hasChanges {
            await sendDataChanged()
        }
    }
    
    @MainActor
    private func sendDataChanged() async {
        dataChanged.send()
    }
}
