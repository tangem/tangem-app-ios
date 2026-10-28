//
//  TangemPayCustomerSummaryResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCustomerSummaryResponse: Codable, Equatable {
    public let customerId: String
    public let customerStatus: CustomerStatus
    public let hidden: Bool
    public let kycStatus: KYCStatus
    public let paymentAccount: PaymentAccount
    public let bankingAccount: BankingAccount
}

// MARK: - Nested Types

public extension TangemPayCustomerSummaryResponse {
    enum CustomerStatus: String, Codable {
        case new = "NEW"
        case active = "ACTIVE"
        case blocked = "BLOCKED"
        case former = "FORMER"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue.uppercased()) ?? .undefined
        }
    }

    enum KYCStatus: String, Codable {
        case required = "REQUIRED"
        case inProgress = "IN_PROGRESS"
        case approved = "APPROVED"
        case declined = "DECLINED"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue.uppercased()) ?? .undefined
        }
    }

    struct PaymentAccount: Codable, Equatable {
        public let id: String?
        public let activation: Activation
        public let cards: Cards
    }

    struct BankingAccount: Codable, Equatable {
        public let id: String?
        public let activation: Activation
    }

    struct Activation: Codable, Equatable {
        public let status: Status
        public let step: Step?
        public let failureReason: FailureReason?

        public enum Status: String, Codable {
            case notStarted = "NOT_STARTED"
            case unavailable = "UNAVAILABLE"
            case processing = "PROCESSING"
            case failed = "FAILED"
            case completed = "COMPLETED"
            case deactivated = "DEACTIVATED"
            case undefined = "UNDEFINED"

            public init(from decoder: Decoder) throws {
                let rawValue = try decoder.singleValueContainer().decode(String.self)
                self = Self(rawValue: rawValue.uppercased()) ?? .undefined
            }
        }

        public enum Step: String, Codable {
            case awaitingKYC = "AWAITING_KYC"
            case awaitingDeposit = "AWAITING_DEPOSIT"
            case issuing = "ISSUING"
            case undefined = "UNDEFINED"

            public init(from decoder: Decoder) throws {
                let rawValue = try decoder.singleValueContainer().decode(String.self)
                self = Self(rawValue: rawValue.uppercased()) ?? .undefined
            }
        }

        public enum FailureReason: String, Codable {
            case rainRejected = "RAIN_REJECTED"
            case depositTimeout = "DEPOSIT_TIMEOUT"
            case technical = "TECHNICAL"
            case undefined = "UNDEFINED"

            public init(from decoder: Decoder) throws {
                let rawValue = try decoder.singleValueContainer().decode(String.self)
                self = Self(rawValue: rawValue.uppercased()) ?? .undefined
            }
        }
    }

    struct Cards: Codable, Equatable {
        public let active: Int
        public let frozen: Int
        public let pending: Int
    }
}
