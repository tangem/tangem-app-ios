//
//  AllowanceChecking.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceChecking {
    /// One-tap approve+swap needs fee estimation with an allowance state override — currently EVM-only.
    var supportsOneTapApprove: Bool { get }

    func allowanceState(amount: Decimal, spender: String, policy: ApprovePolicy) async throws -> AllowanceCheckerResult
    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> ApproveTransactionData
}

public enum AllowanceCheckerResult {
    case enoughAllowance
    case approveRequired(ApproveTransactionData)
    case revokeAndApproveRequired(revoke: ApproveTransactionData, approve: ApproveTransactionData)
}

public enum AllowanceCheckerError: String, Hashable, LocalizedError {
    case contractAddressNotFound
    case wrongAmountType

    public var errorDescription: String? {
        switch self {
        case .contractAddressNotFound: "Contract address not found."
        case .wrongAmountType: "Wrong amount type."
        }
    }
}
