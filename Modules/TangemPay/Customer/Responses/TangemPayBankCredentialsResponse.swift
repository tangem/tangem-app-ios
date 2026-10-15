//
//  TangemPayBankCredentialsResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayBankCredentialsResponse: Decodable {
    public let beneficiaryName: String
    public let beneficiaryAddress: String
    public let beneficiaryBankName: String
    public let beneficiaryBankAddress: String
    public let accountNumber: String
    public let routingNumber: String
    public let depositLimit: DepositLimit?
}

// MARK: - DepositLimit

public extension TangemPayBankCredentialsResponse {
    struct DepositLimit: Decodable {
        public let amount: Decimal
        public let period: String?
    }
}
