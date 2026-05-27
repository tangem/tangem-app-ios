//
//  ElectrumDTO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/*
 Electrum responses
 Supports specs:

 - Original: https://bitcoincash.network/electrum/protocol-methods.html
 - Rostrum (Nexa): https://bitcoinunlimited.gitlab.io/rostrum/
 - Radiant: https://electrumx.readthedocs.io/en/latest/
 - Fact0rn: https://electrumx-spesmilo.readthedocs.io/en/latest//
 */

enum ElectrumDTO {
    enum Response {
        struct Balance: Decodable {
            let confirmed: Int
            let unconfirmed: Int
        }

        struct History: Decodable {
            let height: Decimal
            let txHash: String
        }

        struct ListUnspent: Decodable {
            let hasToken: Bool?
            let height: Decimal
            let outpointHash: String?
            let txHash: String
            let txPos: Int
            let value: Decimal
        }

        struct Broadcast: Decodable {
            let txHash: String
        }

        struct Transaction: Decodable {
            let blockhash: String?
            let blocktime: Int?
            let confirmations: Int?
            let hash: String
            let hex: String
            let locktime: Int
            let size: Int
            let time: Int?
            let txid: String
            let version: Int
            let vin: [Vin]
            let vout: [Vout]
            let fee: Decimal?
            let feeSatoshi: Decimal?
        }

        struct Vin: Decodable {
            // Can be coinbase
            // {"coinbase":"03157402","txinwitness":["..."],"sequence":0}
            let scriptSig: ScriptSig?
            let sequence: UInt64?
            let txid: String?
            let vout: Int?
        }

        struct Vout: Decodable {
            let n: Int
            let scriptPubKey: ScriptPubKey
            let value: Decimal
        }

        struct ScriptSig: Decodable {
            let asm: String
            let hex: String
        }

        struct ScriptPubKey: Decodable {
            let addresses: [String]?
            let address: String?
            let asm: String
            let hex: String
            let reqSigs: Int?
            let type: String
        }
    }
}
