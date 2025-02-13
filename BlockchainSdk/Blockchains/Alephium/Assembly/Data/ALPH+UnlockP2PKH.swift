//
//  ALPH+P2PKH.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum Unlock {
        struct P2PKH: UnlockScript {
            let publicKeyData: Data

            static let length: Int = 33

            // We don't use Serde[Int] here as the value of Hint is random, no need of serde optimization
            static var unlockSerde: ALPH.AnySerde<UnlockScript> {
                ALPH.BytesSerde(length: length).xmap(to: { P2PKH(publicKeyData: $0) }, from: { $0.publicKeyData })
            }
        }
    }

    enum Lockup {
        struct P2PKH: LockupScript {
            let pkHash: ALPH.Blake2b

            var scriptHint: ScriptHint {
                return ScriptHint.fromHash(pkHash.bytes)
            }
        }
    }
}
