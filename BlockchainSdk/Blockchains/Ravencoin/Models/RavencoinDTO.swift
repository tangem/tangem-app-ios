//
//  RavencoinDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum RavencoinDTO {
    enum UTXO {
        // https://github.com/RavenDevKit/insight-api/blob/master/docs/example_responses/utxo_with_assets.md
        struct Response: Decodable {
            let txid: String
            let vout: Int
            let satoshis: UInt64
            let scriptPubKey: String
            let height: Int?
        }
    }

    enum TransactionInfo {
        /// https://github.com/RavenDevKit/insight-api/blob/master/docs/example_responses/tx_with_assets.md
        struct Response: Decodable {
            let txid: String
            let vin: [Vin]
            let vout: [Vout]
            let blockhash: String?
            let blockheight: Int
            let confirmations: Int
            let time: Int?
            let valueIn: Decimal
            let valueOut: Decimal
            /// Fee in RVN
            let fees: Decimal

            struct Vin: Decodable {
                let txid: String
                let vout: Int
                let addr: String
                let valueSat: UInt64
                let value: Decimal
            }

            struct Vout: Decodable {
                /// Amount in RVN
                let value: String
                let n: Int?
                let scriptPubKey: ScriptPubKey
                let spentTxId: String?

                struct ScriptPubKey: Decodable {
                    let hex: String?
                    let asm: String?
                    let addresses: [String]
                    let type: String?
                }
            }
        }
    }

    enum Fee {
        struct Request: Encodable {
            let nbBlocks: Int
            let mode: RavencoinFeeMode

            enum RavencoinFeeMode: String, Encodable {
                case economical
                case conservative
            }

            init(nbBlocks: Int, mode: RavencoinFeeMode = .economical) {
                self.nbBlocks = nbBlocks
                self.mode = mode
            }
        }
    }

    enum Send {
        struct Request: Encodable {
            let rawtx: String
        }

        struct Response: Decodable {
            let txid: String
        }
    }
}
