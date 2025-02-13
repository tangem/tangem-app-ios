//
//  ALPH+TransactionInputDataSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum TxInputDataSerde {
        static var serde: Product2<AssetOutputRef, UnlockScript, TxInputInfo> {
            Product2(
                pack: { TxInputInfo(outputRef: $0, unlockScript: $1) },
                unpack: { Tuple2(a0: $0.outputRef, a1: $0.unlockScript) },
                serdeA0: AnySerde(AssetOutputRef.serde),
                serdeA1: AnySerde(UnlockScriptSerde())
            )
        }
    }
}
