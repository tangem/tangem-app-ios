//
//  ElectrumAddressInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use UTXOResponse")
struct ElectrumAddressInfo {
    let balance: Decimal
    let unconfirmed: Decimal
    let outputs: [ElectrumUTXO]
}

@available(*, deprecated, message: "Use UnspentOutput")
struct ElectrumUTXO {
    let position: Int
    let hash: String
    let value: Decimal
    let height: Decimal

    var isConfirmed: Bool { height != 0 }
    var isNonConfirmed: Bool { height == 0 }
}

struct ElectrumScriptUTXO {
    let transactionHash: String
    let outputs: [Vout]

    struct Vout {
        let n: Int
        let scriptPubKey: ScriptPubKey
    }

    struct ScriptPubKey {
        let addresses: [String]
        let hex: String
    }
}
