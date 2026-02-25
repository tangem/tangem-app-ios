//
//  SolanaTransactionHistoryTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils
import struct AnyCodable.AnyEncodable
import struct AnyCodable.AnyDecodable

struct SolanaTransactionHistoryTarget: TargetType {
    let node: NodeInfo
    let request: Request

    var baseURL: URL { node.url }
    var path: String { "" }
    var method: Moya.Method { .post }

    var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }

    var headers: [String: String]? {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]

        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }

        return headers
    }
}

extension SolanaTransactionHistoryTarget {
    enum Request {
        case getSignaturesForAddress(address: String, limit: Int, before: String?)
        case getTransaction(signature: String)

        var id: Int { 1 }

        var method: String {
            switch self {
            case .getSignaturesForAddress:
                return "getSignaturesForAddress"
            case .getTransaction:
                return "getTransaction"
            }
        }

        var params: (any Encodable)? {
            switch self {
            case .getSignaturesForAddress(let address, let limit, let before):
                return [
                    AnyEncodable(address),
                    AnyEncodable(GetSignaturesConfig(limit: limit, before: before)),
                ]
            case .getTransaction(let signature):
                return [
                    AnyEncodable(signature),
                    AnyEncodable(GetTransactionConfig()),
                ]
            }
        }
    }
}

extension SolanaTransactionHistoryTarget {
    private struct GetSignaturesConfig: Encodable {
        let limit: Int
        let before: String?
    }

    private struct GetTransactionConfig: Encodable {
        let encoding: String = "jsonParsed"
        let maxSupportedTransactionVersion: Int = 0
    }
}

extension SolanaTransactionHistoryTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        request.method
    }

    var shouldLogResponseBody: Bool { true }
}

enum SolanaTransactionHistoryDTO {
    struct SignatureItem: Decodable {
        let blockTime: Int?
        let confirmationStatus: String?
        let err: AnyDecodable?
        let memo: String?
        let signature: String
        let slot: UInt64?
    }

    struct TransactionDetails: Decodable {
        let blockTime: Int?
        let meta: Meta?
        let slot: UInt64?
        let transaction: Transaction
        let version: AnyDecodable?

        struct Meta: Decodable {
            let err: AnyDecodable?
            let fee: UInt64?
            let innerInstructions: [InnerInstruction]
            let postBalances: [UInt64]
            let preBalances: [UInt64]
            let postTokenBalances: [TokenBalance]
            let preTokenBalances: [TokenBalance]
            let rewards: [AnyDecodable]

            struct InnerInstruction: Decodable {
                let index: Int?
                let instructions: [Instruction]
            }

            struct TokenBalance: Decodable {
                let accountIndex: Int?
                let mint: String?
                let owner: String?
                let programId: String?
                let uiTokenAmount: TokenAmount?
            }

            struct TokenAmount: Decodable {
                let amount: String?
                let decimals: Int?
                let uiAmount: Decimal?
                let uiAmountString: String?
            }

            private enum CodingKeys: String, CodingKey {
                case err
                case fee
                case innerInstructions
                case postBalances
                case preBalances
                case postTokenBalances
                case preTokenBalances
                case rewards
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                err = try container.decodeIfPresent(AnyDecodable.self, forKey: .err)
                fee = try container.decodeIfPresent(UInt64.self, forKey: .fee)
                innerInstructions = try container.decodeIfPresent([InnerInstruction].self, forKey: .innerInstructions) ?? []
                postBalances = try container.decodeIfPresent([UInt64].self, forKey: .postBalances) ?? []
                preBalances = try container.decodeIfPresent([UInt64].self, forKey: .preBalances) ?? []
                postTokenBalances = try container.decodeIfPresent([TokenBalance].self, forKey: .postTokenBalances) ?? []
                preTokenBalances = try container.decodeIfPresent([TokenBalance].self, forKey: .preTokenBalances) ?? []
                rewards = try container.decodeIfPresent([AnyDecodable].self, forKey: .rewards) ?? []
            }
        }

        struct Transaction: Decodable {
            let message: Message
            let signatures: [String]

            struct Message: Decodable {
                let accountKeys: [AccountKey]
                let instructions: [Instruction]
            }
        }
    }

    struct Instruction: Decodable {
        let parsed: Parsed?
        let program: String?
        let programId: String?

        struct Parsed: Decodable {
            let info: Info?
            let type: String?

            struct Info: Decodable {
                let source: String?
                let destination: String?
                let lamports: UInt64?
                let amount: String?
                let tokenAmount: TransactionDetails.Meta.TokenAmount?
            }
        }

        private enum CodingKeys: String, CodingKey {
            case parsed
            case program
            case programId
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            program = try container.decodeIfPresent(String.self, forKey: .program)
            programId = try container.decodeIfPresent(String.self, forKey: .programId)

            // Solana may return `parsed` as a string or any other non-object payload.
            // We ignore those shapes because history classification relies on typed object fields.
            if let parsedObject = try? container.decodeIfPresent(Parsed.self, forKey: .parsed) {
                parsed = parsedObject
                return
            }
            parsed = nil
        }
    }

    enum AccountKey: Decodable {
        case user(Account)
        case raw(String)

        var pubkey: String {
            switch self {
            case .user(let account):
                return account.pubkey
            case .raw(let value):
                return value
            }
        }

        struct Account: Decodable {
            let pubkey: String
            let signer: Bool?
            let source: String?
            let writable: Bool?
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let account = try? container.decode(Account.self) {
                self = .user(account)
                return
            }

            self = .raw(try container.decode(String.self))
        }
    }
}
