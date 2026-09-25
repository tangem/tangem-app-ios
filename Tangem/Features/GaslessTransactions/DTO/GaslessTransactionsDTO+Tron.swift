//
//  GaslessTransactionsDTO+Tron.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

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

extension GaslessTransactionsDTO.APIError {
    /// Tron activation failures arrive as `TangemAPIError`, with the machine code in `message`.
    struct TronActivation: LocalizedError {
        let code: Code
        let message: String?

        var errorDescription: String? {
            switch code {
            case .activationRateLimited:
                Localization.gaslessTronActivationAttemptsLimit
            case .activationHalted:
                Localization.gaslessTronActivationTryAgainLater
            default:
                message ?? code.rawValue
            }
        }

        init?(apiError: TangemAPIError) {
            guard let message = apiError.message, let code = Code(rawValue: message) else {
                return nil
            }

            self.code = code
            self.message = message
        }

        enum Code: String, CaseIterable {
            case accountNotActivated = "TRON_ACCOUNT_NOT_ACTIVATED"
            case activationBalanceTooLow = "TRON_ACTIVATION_BALANCE_TOO_LOW"
            case activationRateLimited = "TRON_ACTIVATION_RATE_LIMITED"
            case activationHalted = "TRON_ACTIVATION_HALTED"
            case activationWalletIdRequired = "TRON_ACTIVATION_WALLET_ID_REQUIRED"
            case activationInProgress = "TRON_ACTIVATION_IN_PROGRESS"
            case activationFailed = "TRON_ACTIVATION_FAILED"
            case activationRejected = "TRON_ACTIVATION_REJECTED"
            case activationBudgetExceeded = "TRON_ACTIVATION_BUDGET_EXCEEDED"
        }
    }
}

extension GaslessTransactionsDTO.Response {
    struct TronTokens: Decodable {
        let tokens: [TronFeeToken]

        private enum CodingKeys: String, CodingKey {
            case result
        }

        private enum ResultKeys: String, CodingKey {
            case tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let result = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            tokens = try result.decode([TronFeeToken].self, forKey: .tokens)
        }
    }

    struct TronFeeToken: Decodable {
        let address: String
        let symbol: String
        let decimals: Int
        let chain: String
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
            expiresAt = try result.decode(Date.self, forKey: .expiresAt)
        }
    }

    struct TronSubmit: Decodable {
        let compensationTxHash: String
        let originalTxHash: String
        let status: Status

        enum Status: String, Decodable {
            case broadcast
            case partialFailed = "partial_failed"
            case failed
        }

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
            status = try result.decode(Status.self, forKey: .status)
        }
    }
}
