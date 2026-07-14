//
//  GaslessTransactionsDTO+Tron.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Request {
    struct TronEstimate: Encodable, Equatable {
        let fromAddress: String
        let toAddress: String
        let tokenContract: String
        let amount: String
        let feeTokenContract: String
    }

    struct TronSubmit: Encodable, Equatable {
        let quoteId: String
        let signedCompensationTx: String
        let signedOriginalTx: String
    }
}

extension GaslessTransactionsDTO.Response {
    struct TronTokens: Decodable {
        let tokens: [FeeToken]

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            tokens = try result.decode([FeeToken].self, forKey: .tokens)
        }
    }

    struct TronEstimate: Decodable {
        let quoteId: String
        let feeRecipient: String
        let compensationToken: String
        let compensationAmount: String
        let compensationAmountRaw: String
        let estimate: Estimate
        let expiresAt: Date

        struct Estimate: Decodable {
            let energy: Int
            let bandwidth: Int
            let trxCost: String
        }

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case quoteId
            case feeRecipient
            case compensationToken
            case compensationAmount
            case compensationAmountRaw
            case estimate
            case expiresAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            quoteId = try result.decode(String.self, forKey: .quoteId)
            feeRecipient = try result.decode(String.self, forKey: .feeRecipient)
            compensationToken = try result.decode(String.self, forKey: .compensationToken)
            compensationAmount = try result.decode(String.self, forKey: .compensationAmount)
            compensationAmountRaw = try result.decode(String.self, forKey: .compensationAmountRaw)
            estimate = try result.decode(Estimate.self, forKey: .estimate)
            let expiresAtString = try result.decode(String.self, forKey: .expiresAt)
            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallbackFormatter = ISO8601DateFormatter()

            guard let expiresAt = fractionalFormatter.date(from: expiresAtString) ?? fallbackFormatter.date(from: expiresAtString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .expiresAt,
                    in: result,
                    debugDescription: "Invalid ISO-8601 date"
                )
            }

            self.expiresAt = expiresAt
        }
    }

    struct TronSubmit: Decodable {
        let compensationTxHash: String
        let originalTxHash: String
        let status: String

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case compensationTxHash
            case originalTxHash
            case status
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            compensationTxHash = try result.decode(String.self, forKey: .compensationTxHash)
            originalTxHash = try result.decode(String.self, forKey: .originalTxHash)
            status = try result.decode(String.self, forKey: .status)
        }
    }
}
