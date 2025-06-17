//
//  AllowanceProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceProvider {
    var isSupportAllowance: Bool { get }

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ExpressApprovePolicy) async throws -> AllowanceState
    func didSendApproveTransaction(for spender: String)
}

public extension AllowanceProvider {
    func allowanceState(request: ExpressManagerSwappingPairRequest, spender: String) async throws -> AllowanceState {
        let contractAddress = request.pair.source.expressCurrency.contractAddress
        if contractAddress == ExpressConstants.coinContractAddress {
            return .enoughAllowance
        }

        assert(contractAddress != ExpressConstants.coinContractAddress)

        return try await allowanceState(amount: request.amount, spender: spender, approvePolicy: request.approvePolicy)
    }
}

public enum AllowanceState: Hashable {
    case permissionRequired(ApproveTransactionData)
    case approveTransactionInProgress
    case enoughAllowance
}

public struct ApproveTransactionData: Hashable {
    public let txData: Data
    public let spender: String
    public let toContractAddress: String
    public let fee: Fee

    public init(txData: Data, spender: String, toContractAddress: String, fee: Fee) {
        self.txData = txData
        self.spender = spender
        self.toContractAddress = toContractAddress
        self.fee = fee
    }
}
