//
//  Alephium+Serializer.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    protocol Serializer {
        associatedtype T

        func serialize(_ input: T) -> Data
    }
}
