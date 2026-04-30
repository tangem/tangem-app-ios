//
//  Alephium+Staging.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct Staging<T> {
        let value: T
        let rest: Data

        func mapValue<B>(_ transform: (T) -> B) -> Staging<B> {
            return Staging<B>(value: transform(value), rest: rest)
        }
    }
}
