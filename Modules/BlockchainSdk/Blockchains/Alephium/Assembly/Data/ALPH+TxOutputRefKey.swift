//
//  ALPH+TxOutputRefKey.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct TxOutputRefKey: Hashable {
        // MARK: - Properties

        let value: Blake2b

        // MARK: - Init

        init(value: Blake2b) {
            self.value = value
        }

        // MARK: - Serde

        static var serde: ALPH.AnySerde<ALPH.TxOutputRefKey> {
            ALPH.Blake2b.serde.xmap(to: { TxOutputRefKey(value: $0) }, from: { $0.value })
        }
    }
}
