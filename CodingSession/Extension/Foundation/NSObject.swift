//
//  NSObject.swift
//  CodingSession
//
//  Created by Yury Krainik on 08/03/2024.
//

import Foundation

public extension NSObject {
    static var className: String {
        String(describing: self)
    }
}
