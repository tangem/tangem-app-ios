//
//  ALPH+Flags.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum Flags {
        static let none: Int = 0
        static let some: Int = 1
        static let left: Int = 0
        static let right: Int = 1

        static let noneB: UInt8 = .init(none)
        static let someB: UInt8 = .init(some)
        static let leftB: UInt8 = .init(left)
        static let rightB: UInt8 = .init(right)
    }
}
