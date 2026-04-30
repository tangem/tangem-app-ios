//
//  ALPH+Blake2b.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension ALPH {
    struct Blake2b: Hashable {
        private static let defaultLength = 32

        let bytes: Data

        var length: Int {
            bytes.count
        }

        static func hash(_ input: Data) -> Blake2b {
            let hash = input.hashBlake2b(outputLength: defaultLength) ?? Data()
            return Blake2b(bytes: hash)
        }

        // MARK: - Serde

        static var serde: ALPH.AnySerde<ALPH.Blake2b> {
            ALPH.BytesSerde(length: defaultLength).xmap(
                to: { Blake2b(bytes: $0) },
                from: { $0.bytes }
            )
        }
    }
}
