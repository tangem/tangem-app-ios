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
import TangemLocalization

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
    let approveData: ApproveTransactionData
    let approvalFlow: ExpressProviderManagerState.ApprovalFlow
    let sourceToken: any SendSourceToken
    let tokenFeeProvidersManager: any TokenFeeProvidersManager
    let localization: ApproveLocalization
}

extension ApproveFlowInput {
    func makeApproveInteractorState() -> ApproveInteractor.ApproveInteractorState {
        switch approvalFlow {
        case .approve:
            return .approve(data: approveData)
        case .revokeAndApprove(let revokeData, let feeUnit):
            return .revokeAndApprove(revoke: revokeData, approve: approveData, feeUnit: feeUnit)
        }
    }
}

// MARK: - ApproveLocalization

struct ApproveLocalization {
    let title: String
    let subtitle: String
    let feeFooterText: String
}

// MARK: - ApprovalFlow + Localization

extension ExpressProviderManagerState.ApprovalFlow {
    func makeLocalization(providerName: String, currencySymbol: String) -> ApproveLocalization {
        switch self {
        case .revokeAndApprove:
            return ApproveLocalization(
                title: Localization.updateApprovalPermissionTitle,
                subtitle: Localization.updateApprovalPermissionSubtitle,
                feeFooterText: Localization.updateApprovalPermissionFeeNote
            )
        case .approve:
            return ApproveLocalization(
                title: Localization.swappingPermissionHeader,
                subtitle: Localization.givePermissionSwapSubtitle(providerName, currencySymbol),
                feeFooterText: Localization.swapGivePermissionFeeFooter
            )
        }
    }
}
