//
//  AlephiumNetworkResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A top-level namespace.
enum AlephiumNetworkResponse {
    struct BuildTransferTxResult: Decodable {
        let unsignedTx: String
        let gasAmount: Int
        let gasPrice: String
        let txId: String
        let fromGroup: Int
        let toGroup: Int
    }

    struct UTXOs: Decodable {
        let utxos: [UTXO]
    }

    struct UTXO: Decodable {
        let ref: Ref
        let amount: String
        let tokens: [Token]
        let lockTime: Int64
        let additionalData: String
    }

    struct Ref: Decodable {
        let hint: Int
        let key: String
    }

    struct Token: Decodable {
        let id: String
        let amount: String
    }

    struct Submit: Decodable {
        let txId: String
    }

    struct Status: Decodable {
        let type: StatusType
    }

    enum StatusType: String, Decodable {
        case confirmed = "Confirmed"
        case memPooled = "MemPooled"
        case txNotFound = "TxNotFound"
    }
}
