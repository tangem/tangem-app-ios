//
//  TangemPayBankCredentialsResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct TangemPayBankCredentialsResponse: Decodable {
    public let beneficiaryName: String
    public let beneficiaryAddress: String
    public let beneficiaryBankName: String
    public let beneficiaryBankAddress: String
    public let accountNumber: String
    public let routingNumber: String
    public let rail: String?
    public let fee: Fee?
    public let depositLimit: DepositLimit?
}

// MARK: - Fee

public extension TangemPayBankCredentialsResponse {
    struct Fee: Decodable {
        public let type: String
        public let amount: String

        public var flatAmount: Decimal? {
            guard type == Constants.flatType else {
                return nil
            }

            return Decimal(stringValue: amount)
        }
    }
}

// MARK: - DepositLimit

public extension TangemPayBankCredentialsResponse {
    struct DepositLimit: Decodable {
        public let amount: Decimal
        public let period: String?
    }
}

// MARK: - Constants

private extension TangemPayBankCredentialsResponse.Fee {
    enum Constants {
        static let flatType = "flat"
    }
}
