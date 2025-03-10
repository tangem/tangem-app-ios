//
//  TangemError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol TangemError: LocalizedError {
    var subsystemCode: Int { get }
    var errorCode: Int { get }
}

public extension TangemError where Self: RawRepresentable, Self.RawValue == Int {
    var errorCode: Int {
        rawValue
    }
}
