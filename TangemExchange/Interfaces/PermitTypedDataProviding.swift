//
//  PermitTypedDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

public protocol PermitTypedDataService {
    /// String which will be used to call `permit` data in smart-contract
    func buildPermitCallData(for currency: Currency, parameters: PermitParameters) async throws -> String
}

public struct PermitParameters {
    public let walletAddress: String
    public let spenderAddress: String
    public let amount: Decimal
    public let deadline: Date

    public init(walletAddress: String, spenderAddress: String, amount: Decimal, deadline: Date) {
        self.walletAddress = walletAddress
        self.spenderAddress = spenderAddress
        self.amount = amount
        self.deadline = deadline
    }
}
