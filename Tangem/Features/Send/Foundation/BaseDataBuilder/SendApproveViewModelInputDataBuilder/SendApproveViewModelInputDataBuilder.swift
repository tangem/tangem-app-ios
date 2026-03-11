//
//  SendApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation
import BlockchainSdk

protocol SendApproveViewModelInputDataBuilder {
    func makeApproveFlowFactory() throws -> ApproveFlowFactory
}

enum SendApproveViewModelInputDataBuilderError: LocalizedError {
    case notSupported
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notSupported: "Approve not supported"
        case .notFound(let item): "\(item) not found"
        }
    }
}

// MARK: - ApproveFlowDataProvider

/// Thin provider that extracts a snapshot of approve-related data from the model.
protocol ApproveFlowDataProvider {
    func approveFlowInput() throws -> ApproveFlowInput
}

// MARK: - ApproveFlowInput

struct ApproveFlowInput {
    let approveAmount: Decimal
    let selectedPolicy: BSDKApprovePolicy
    let approveData: ApproveTransactionData
    let sourceToken: any SendSourceToken
    let tokenFeeProvidersManager: any TokenFeeProvidersManager
    let localization: ApproveLocalization
}

// MARK: - ApproveLocalization

struct ApproveLocalization {
    let subtitle: String
    let feeFooterText: String
}
