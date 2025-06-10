//
//  ALPH+AssetOutputRef.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing an asset output reference in the Alephium blockchain
    /// It contains information about the hint and key of the output reference
    struct AssetOutputRef: TxOutputRef {
        /// The hint of the output reference
        let hint: Hint

        /// The key of the output reference
        let key: TxOutputRefKey

        /// Returns true if the output reference is an asset type
        var isAssetType: Bool { true }

        /// Returns true if the output reference is a contract type
        var isContractType: Bool { false }

        /// Hashes the output reference into a hasher
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }

        /// The serde for the asset output reference
        static var serde: Product2<Hint, ALPH.TxOutputRefKey, AssetOutputRef> {
            Product2<Hint, ALPH.TxOutputRefKey, AssetOutputRef>(
                pack: { AssetOutputRef(hint: $0, key: $1) },
                unpack: { Tuple2(a0: $0.hint, a1: $0.key) },
                serdeA0: AnySerde(Hint.serde),
                serdeA1: AnySerde(TxOutputRefKey.serde)
            )
        }
    }
}
