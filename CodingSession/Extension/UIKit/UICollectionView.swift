//
//  UICollectionView.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import UIKit

extension UICollectionView {

    func register<T: UICollectionViewCell>(_ cellType: T.Type, bundle: Bundle? = nil) {
        let className = cellType.className

        register(T.self, forCellWithReuseIdentifier: className)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(with type: T.Type, for indexPath: IndexPath) -> T {
        // swiftlint:disable:next force_cast
        dequeueReusableCell(withReuseIdentifier: type.className, for: indexPath) as! T
    }
}
