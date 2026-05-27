//
//  KaspaDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum KaspaDTO {
    enum UTXO {
        struct Response: Decodable {
            let outpoint: Outpoint
            let utxoEntry: UtxoEntry

            struct Outpoint: Decodable {
                let transactionId: String
                let index: Int
            }

            struct UtxoEntry: Decodable {
                let amount: String
                let scriptPublicKey: ScriptPublicKey
                let blockDaaScore: String?

                struct ScriptPublicKey: Codable {
                    let scriptPublicKey: String
                }
            }
        }
    }

    enum TransactionInfo {
        struct Request: Encodable {
            let inputs: Bool = true
            let outputs: Bool = true
            let resolvePreviousOutpoints: Resolve = .light

            enum Resolve: String, Encodable {
                case no
                case light
                case full
            }
        }

        struct Response: Decodable {
            let transactionId: String
            let mass: String
            let blockTime: Int?
            let inputs: [Input]
            let outputs: [Output]

            /*
             let subnetwork_id: String?
             let hash: String?
             let payload: String?
             let block_hash: [String]?
             let is_accepted: Bool?
             let accepting_block_hash: String?
             let accepting_block_blue_score: Int?
             let accepting_block_time: Int?
              */

            struct Input: Decodable {
                let transactionId: String
                let previousOutpointAddress: String
                let previousOutpointAmount: UInt64

                /*
                 let index: Int?
                 let previousOutpointHash: String?
                 let previousOutpointIndex: String?
                 let previousOutpointResolved: Output?
                 let signatureScript: String?
                 let sigOpCount: String?
                 */
            }

            struct Output: Decodable {
                let transactionId: String
                let amount: UInt64
                let scriptPublicKeyAddress: String

                /*
                 let index: Int?
                 let scriptPublicScriptPublicKey: String?
                 let scriptPublicScriptPublicKeyType: String?
                 let acceptingBlockHash: String?
                 */
            }
        }
    }

    enum EstimateFee {
        struct Response: Decodable {
            let priorityBucket: Fee
            let normalBuckets: [Fee]
            let lowBuckets: [Fee]

            struct Fee: Decodable {
                let feerate: UInt64
                let estimatedSeconds: Decimal
            }
        }
    }

    enum Mass {
        struct Response: Decodable {
            let mass: UInt64
            let storageMass: UInt64
            let computeMass: UInt64
        }
    }

    enum Send {
        struct Request: Encodable {
            let transaction: Transaction

            struct Transaction: Encodable {
                let version: Int
                let inputs: [Input]
                let outputs: [Output]
                let lockTime: Int
                let subnetworkId: String

                struct Input: Encodable {
                    let previousOutpoint: PreviousOutpoint
                    let signatureScript: String
                    let sequence: Int
                    let sigOpCount: Int

                    struct PreviousOutpoint: Encodable {
                        let transactionId: String
                        let index: Int
                    }

                    init(previousOutpoint: PreviousOutpoint, signatureScript: String, sequence: Int = 0, sigOpCount: Int = 1) {
                        self.previousOutpoint = previousOutpoint
                        self.signatureScript = signatureScript
                        self.sequence = sequence
                        self.sigOpCount = sigOpCount
                    }
                }

                struct Output: Encodable {
                    let amount: UInt64
                    let scriptPublicKey: ScriptPublicKey
                }

                struct ScriptPublicKey: Encodable {
                    let scriptPublicKey: String
                    let version: Int

                    init(scriptPublicKey: String, version: Int = 0) {
                        self.scriptPublicKey = scriptPublicKey
                        self.version = version
                    }
                }

                init(
                    version: Int = 0,
                    inputs: [Input],
                    outputs: [Output],
                    lockTime: Int = 0,
                    subnetworkId: String = "0000000000000000000000000000000000000000"
                ) {
                    self.version = version
                    self.inputs = inputs
                    self.outputs = outputs
                    self.lockTime = lockTime
                    self.subnetworkId = subnetworkId
                }
            }
        }

        struct Response: Decodable {
            let transactionId: String
        }
    }
}
