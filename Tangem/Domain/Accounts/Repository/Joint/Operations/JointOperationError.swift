//
//  JointOperationError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointOperationError: LocalizedError, Equatable {
    case accountUnavailable
    case walletUnavailable
    /// Only an activated account has the address the operation is signed for.
    case accountNotActive
    /// A Safe is operated by chain id, which only an EVM network has.
    case unsupportedNetwork
    case networkBusy
    /// The Safe was deployed, or found not to be, since the fee was quoted.
    case safeStateChanged
    /// Another operation of this Safe executed since this one was created, so the nonce it carries is spent.
    case operationSuperseded
    case compositionMismatch
    /// Anything but a plain transfer or a token `transfer`, or a call aimed at the Safe itself.
    case unsupportedOperationForm
    /// The fee was not quoted as a Safe operation, so there are no gas terms to sign.
    case missingFeeParameters

    var errorDescription: String? {
        switch self {
        case .accountUnavailable: "The joint account is no longer available"
        case .walletUnavailable: "The wallet of the joint account is no longer available"
        case .accountNotActive: "The joint account is not active"
        case .unsupportedNetwork: "The joint account does not operate in this network"
        case .networkBusy: "The network already has an operation in flight"
        case .safeStateChanged: "The Safe changed since the fee was quoted"
        case .operationSuperseded: "The Safe has moved past this operation"
        case .compositionMismatch: "The Safe's owners or threshold differ from the account's members"
        case .unsupportedOperationForm: "This operation form is not supported"
        case .missingFeeParameters: "The fee carries no Safe operation terms"
        }
    }
}
