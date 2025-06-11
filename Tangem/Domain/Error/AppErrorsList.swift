//
//  AppErrorsList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Each error code must follow this format: xxxyyyzzz where
/// xxx - Feature code
/// yyy - Subsystem code
/// zzz - Specific error code
/// If you need to add new feature add it to list below incrementing last code same for `Subsystems`.
/// If your feature is in separate target, place file with `FeatureErrorsList` and add all errors with `UniversalError` conformance
/// in this separate file. See `VisaErrorsList.swift` for implementation details
///
/// Features:
/// `100` - App error
/// `101` - TangemSdkError
/// `102` - BlockchainSdkError
/// `103` - Express
/// `104` - Visa
/// `105` - Staking
/// `106` - NFT
/// `107` - WalletConnect
///
/// `Subsystems`:
/// `001` - Visa onboarding
/// `002` - Visa user wallet model
/// `003` - Referral
extension VisaOnboardingViewModel.OnboardingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .missingTargetApproveAddress: return 100001001
        case .wrongRemoteState: return 100001001
        }
    }
}

extension VisaUserWalletModel.ModelError: UniversalError {
    var errorCode: Int {
        switch self {
        case .missingRequiredBlockchain: return 100002001
        case .invalidBlockchain: return 100002002
        case .noPaymentAccount: return 100002003
        case .missingPublicKey: return 100002004
        case .failedToGenerateAddress: return 100002005
        case .authorizationError: return 100002006
        case .missingValidRefreshToken: return 100002007
        case .missingCardId: return 100002008
        case .invalidConfig: return 100002009
        case .invalidActivationState: return 100002010
        }
    }
}

extension ReferralViewModel.ReferralError: UniversalError {
    var errorCode: Int {
        switch self {
        case .awardNotLoaded: return 100003001
        case .blockchainNotSupported: return 100003002
        case .invalidToken: return 100003003
        case .decodingError: return 100003004
        case .moyaError(let error):
            guard let response = error.response else {
                return 100003005
            }
            return 100003000 + response.statusCode
        case .unknown(let error):
            let nsError = error as NSError
            // Look for status code at https://osstatus.com
            // if nothing was found - add the specific case to `ReferralError` enum
            return nsError.code
        }
    }
}

extension WalletConnectDAppProposalLoadingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .uriAlreadyUsed:
            107001001
        case .pairingFailed:
            107001002
        case .invalidDomainURL:
            107001003
        case .unsupportedDomain:
            107001004
        case .unsupportedBlockchains:
            107001005
        case .noBlockchainsProvidedByDApp:
            107001006
        case .cancelledByUser:
            107001007
        }
    }
}

extension WalletConnectDAppProposalApprovalError: UniversalError {
    var errorCode: Int {
        switch self {
        case .invalidConnectionRequest:
            107002001
        case .proposalExpired:
            107002002
        case .approvalFailed:
            107002003
        case .rejectionFailed:
            107002004
        case .cancelledByUser:
            107002005
        }
    }
}
