//
//  StakeKitDTO+Actions.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum Actions {
        enum ActionType: String, Hashable, Decodable {
            case stake = "STAKE"
            case unstake = "UNSTAKE"
            case claimRewards = "CLAIM_REWARDS"
            case restakeRewards = "RESTAKE_REWARDS"
            case withdraw = "WITHDRAW"
            case restake = "RESTAKE"
            case claimUnstaked = "CLAIM_UNSTAKED"
            case unlockLocked = "UNLOCK_LOCKED"
            case stakeLocked = "STAKE_LOCKED"
            case vote = "VOTE"
            case revoke = "REVOKE"
            case voteLocked = "VOTE_LOCKED"
            case revote = "REVOTE"
            case rebond = "REBOND"
            case migrate = "MIGRATE"
            case unknown = "UNKNOWN"
        }

        enum ActionStatus: String, Hashable, Decodable {
            case canceled = "CANCELED"
            case created = "CREATED"
            case waitingForNext = "WAITING_FOR_NEXT"
            case processing = "PROCESSING"
            case failed = "FAILED"
            case success = "SUCCESS"
            case unknown = "UNKNOWN"
        }

        struct ActionArgs: Decodable {
            let amount: Amount?
            let duration: Duration?
            let validatorAddress: Required?
            let validatorAddresses: Required?
            let nfts: [NFT]?
            let tronResource: TronResource?
            let signatureVerification: Required?

            struct Amount: Decodable {
                let required: Bool
                let minimum: Decimal
                let maximum: Decimal?
            }

            struct Duration: Codable {
                let required: Bool
                let minimum: Int?
                let maximum: Int?
            }

            struct NFT: Decodable {
                let baycId: Required?
                let maycId: Required?
                let bakcId: Required?
            }

            struct TronResource: Codable {
                let required: Bool
                let options: [String]
            }
        }

        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args

                struct Args: Encodable {
                    let amount: String
                    let validatorAddress: String?
                    let validatorAddresses: [Address]
                }
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: Decimal
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let transactions: [Transaction.Response]?
                let createdAt: Date
            }
        }
    }
}
