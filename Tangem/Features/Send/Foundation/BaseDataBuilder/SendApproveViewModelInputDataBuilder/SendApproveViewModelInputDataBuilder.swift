//
//  SendApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

protocol SendApproveViewModelInputDataBuilder {
    func makeExpressApproveViewModelInput() throws -> ExpressApproveViewModel.Input
}

enum SendApproveViewModelInputDataBuilderError: LocalizedError {
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notSupported: "Approve not supported"
        }
    }
}

protocol SendApproveDataBuilderInput {
    var approveRequestedWithSelectedPolicy: ApprovePolicy? { get }
    var approveRequestedByExpressProvider: ExpressProvider? { get }
    var approveViewModelInput: ApproveViewModelInput? { get }
}

extension SendApproveDataBuilderInput {
    /// For staking
    var approveRequestedByExpressProvider: ExpressProvider? { nil }
}
