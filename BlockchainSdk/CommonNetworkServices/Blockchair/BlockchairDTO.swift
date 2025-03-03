//
//  BlockchairDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum BlockchairDTO {
    enum Address {
        struct Response: Decodable {
            // Key is address
            let data: [String: AddressInfo]
            let context: Context

            struct AddressInfo: Decodable {
                let address: Address
                let transactions: [Transaction]
                let utxo: [Utxo]

                struct Address: Decodable {
                    /*
                     let scriptHex: String
                     let type: String?
                     let balance: Int?
                     let balance_usd: Double?
                     let received: Int?
                     let received_usd: Double?
                     let spent: Int?
                     let spent_usd: Int?
                     let output_count: Int?
                     let unspent_output_count: Int?
                     let first_seen_receiving: String?
                     let last_seen_receiving: String?
                     let first_seen_spending: String?
                     let last_seen_spending: String?
                     let scripthash_type: String?
                     let transaction_count: Int?
                     */
                }

                struct Transaction: Codable {
                    /*
                     let block_id: Int?
                     let hash: String?
                     let time: String?
                     let balance_change: Int?
                     */
                }

                struct Utxo: Codable {
                    let blockId: Int
                    let transactionHash: String
                    let index: Int
                    let value: UInt64
                }
            }

            struct Context: Codable {
                /*
                 let code: Int?
                 let source: String?
                 let limit: String?
                 let offset: String?
                 let results: Int?
                 let state: Int?
                 let market_price_usd: Int?
                 let servers: String?
                 let time: Double?
                 let render_time: Double?
                 let full_time: Double?
                 let request_cost: Int?
                 */
            }
        }
    }

    enum Fee {
        struct Response: Decodable {
            let data: Data

            struct Data: Decodable {
                /// suggested_transaction_fee_per_byte_sat
                let suggestedTransactionFeePerByteSat: Int
            }
        }
    }

    enum Send {
        struct Response: Decodable {
            let data: Data

            struct Data: Decodable {
                /// transaction_hash
                let transactionHash: String
            }
        }
    }

    enum TransactionInfo {
        struct Response: Decodable {
            /// Key is hash
            let data: [String: Transaction]

            struct Transaction: Decodable {
                let transaction: Transaction
                let inputs: [Input]
                let outputs: [Output]

                struct Transaction: Codable {
                    let blockId: Int
                    let hash: String
                    let time: Date
                    let size: Int
                    let lockTime: Int
                    let inputCount: Int
                    let outputCount: Int
                    let inputTotal: Decimal
                    let outputTotal: Decimal
                    let fee: UInt64
                }

                struct Input: Codable {
                    let blockId: Int64
                    let index: Int
                    let transactionHash: String
                    let time: Date
                    let value: UInt64
                    let scriptHex: String
                    let spendingSequence: Int
                    let recipient: String
                }

                struct Output: Codable {
                    let blockId: Int64
                    let index: Int
                    let transactionHash: String
                    let time: Date
                    let value: UInt64
                    let recipient: String
                    let scriptHex: String
                }
            }
        }
    }
}
