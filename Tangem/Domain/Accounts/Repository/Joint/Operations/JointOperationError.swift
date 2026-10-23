//
//  JointOperationError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

enum JointOperationError: UniversalError, Equatable {
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
    case maliciousOperation
    case securityCheckUnavailable
    case operationNotFound
    case notAMember
    case refused(JointOperationRefusal)

    var errorDescription: String? {
        switch self {
        case .accountUnavailable: "The joint account is no longer available"
        case .walletUnavailable: "The wallet of the joint account is no longer available"
        case .accountNotActive: Localization.jointAccountSendNotActivatedSubtitle
        case .unsupportedNetwork: "The joint account does not operate in this network"
        case .networkBusy: Localization.jointAccountSendOperationInProgressSubtitle
        case .safeStateChanged: Localization.jointAccountSendNetworkChangedSubtitle
        case .operationSuperseded: Localization.jointAccountSendNetworkChangedSubtitle
        case .compositionMismatch: Localization.jointAccountSendBlockedSubtitle
        case .unsupportedOperationForm: "This operation form is not supported"
        case .missingFeeParameters: "The fee carries no Safe operation terms"
        case .maliciousOperation: Localization.jointOperationMaliciousSubtitle
        case .securityCheckUnavailable: "The operation could not be checked for security"
        case .operationNotFound: "The joint operation no longer exists"
        case .notAMember: "The wallet holds no slot in this joint account"
        case .refused(.nonceMismatch), .refused(.gasPriceTooLow), .refused(.gasPriceTooHigh): Localization.jointAccountSendNetworkChangedSubtitle
        case .refused: Localization.commonUnknownError
        }
    }

    var errorCode: Int {
        switch self {
        case .accountUnavailable: 100013000
        case .walletUnavailable: 100013001
        case .accountNotActive: 100013002
        case .unsupportedNetwork: 100013003
        case .networkBusy: 100013004
        case .safeStateChanged: 100013005
        case .operationSuperseded: 100013006
        case .compositionMismatch: 100013007
        case .unsupportedOperationForm: 100013008
        case .missingFeeParameters: 100013009
        case .maliciousOperation: 100013010
        case .securityCheckUnavailable: 100013011
        case .operationNotFound: 100013012
        case .notAMember: 100013013
        case .refused(.unsupportedChain): 100013014
        case .refused(.nonceMismatch): 100013015
        case .refused(.invalidBaseGas): 100013016
        case .refused(.gasPriceTooLow): 100013017
        case .refused(.gasPriceTooHigh): 100013018
        case .refused(.gasTokenNotAllowed): 100013019
        case .refused(.invalidRefundReceiver): 100013020
        case .refused(.invalidSafeOperation): 100013021
        case .refused(.invalidSafeAddress): 100013022
        case .refused(.unknown): 100013023
        }
    }
}
