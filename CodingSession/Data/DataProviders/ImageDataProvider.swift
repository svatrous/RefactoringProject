//
//  ImageDataProvider.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import Combine
import UIKit
import Photos

protocol ImageDataProvider {
    var dataChanged: PassthroughSubject<Void, Never> { get }
    func grantAccess() async throws
    func loadAssets() async -> [PHAsset]
    func requestImage(_ asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?) -> Void) -> PHImageRequestID
    func cancelLoading(requestId: PHImageRequestID)
}
