//
//  BlockchairResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

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
                // suggested_transaction_fee_per_byte_sat
                let suggestedTransactionFeePerByteSat: Int
            }
        }
    }

    enum Send {
        struct Response: Decodable {
            let data: Data

            struct Data: Decodable {
                // transaction_hash
                let transactionHash: String
            }
        }
    }

    enum TransactionInfo {
        struct Response: Decodable {
            // Key is hash
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

/// Blockchair transaction that returns in address request
struct BlockchairTransactionShort: Codable {
    let blockId: Int64
    let hash: String
    let time: Date
    let balanceChange: Double
}

/// Returns in address request
struct BlockchairUtxo: Codable {
    let blockId: Int64?
    let transactionHash: String?
    let index: Int?
    let value: UInt64?
}

/// Structure returns when requesting detalization about transaction by transactionHash
struct BlockchairTransactionDetailed: Codable {
    let transaction: BlockchairTransaction
    let inputs: [BlockchairTxInput]
    let outputs: [BlockchairTxOutput]

    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction {
        var destination: String = .unknown
        var source: String = .unknown
        var value: UInt64 = 0
        var isIncoming = false

        if let _ = inputs.first(where: { $0.recipient == userAddress }), let output = outputs.first(where: { $0.recipient != userAddress }) {
            source = userAddress
            destination = output.recipient
            value = output.value
        } else if let output = outputs.first(where: { $0.recipient == userAddress }), let input = inputs.first(where: { $0.recipient != userAddress }) {
            isIncoming = true
            destination = userAddress
            source = input.recipient
            value = output.value
        }

        return PendingTransaction(
            hash: transaction.hash,
            destination: destination,
            value: Decimal(value) / decimalValue,
            source: source,
            fee: transaction.fee / decimalValue,
            date: transaction.time,
            isIncoming: isIncoming,
            transactionParams: BitcoinTransactionParams(inputs: inputs.map { $0.toBitcoinInput() })
        )
    }

    func findUnspentOuputs(for userAddress: String) -> [BitcoinUnspentOutput] {
        let filteredInputs = inputs.filter { $0.recipient == userAddress }

        return filteredInputs.map {
            BitcoinUnspentOutput(transactionHash: $0.transactionHash, outputIndex: $0.index, amount: $0.value, outputScript: $0.scriptHex)
        }
    }
}

/// General information about transaction
struct BlockchairTransaction: Codable {
    let blockId: Int64
    let hash: String
    let time: Date
    let size: Int
    let lockTime: Int
    let inputCount: Int
    let outputCount: Int
    let inputTotal: Decimal
    let outputTotal: Decimal
    let fee: Decimal
}

struct BlockchairTxInput: Codable {
    let blockId: Int64
    let index: Int
    let transactionHash: String
    let time: Date
    let value: UInt64
    let scriptHex: String
    let spendingSequence: Int
    let recipient: String

    func toBitcoinInput() -> BitcoinInput {
        .init(sequence: spendingSequence, address: recipient, outputIndex: index, outputValue: value, prevHash: transactionHash)
    }
}

struct BlockchairTxOutput: Codable {
    let blockId: Int64
    let index: Int
    let transactionHash: String
    let time: Date
    let value: UInt64
    let recipient: String
    let scriptHex: String
}

/// Structure for loading ethereum tokens
struct BlockchairToken: Codable {
    let address: String
    let name: String
    let symbol: String
    let decimals: Int
    let balanceApprox: Decimal
    let balance: String

    enum CodingKeys: String, CodingKey {
        case address = "token_address"
        case name = "token_name"
        case symbol = "token_symbol"
        case decimals = "token_decimals"
        case balanceApprox = "balance_approximate"
        case balance
    }
}
