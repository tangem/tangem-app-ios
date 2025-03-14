//
//  AppErrorsList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Each error code must follow this format: xxxyyyzzz where
/// xxx - Feature code
/// yyy - Subsystem code
/// zzz - Specific error code
/// If you need to add new feature add it to list below incrementing last code same for `Subsystems`.
/// If your feature is in separate target, place file with `FeatureErrorsList` and add all errors with `TangemError` conformance
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
/// `001` - Onboarding
/// `002` - Visa user wallet model
extension VisaOnboardingViewModel.OnboardingError: TangemError {
    var errorCode: Int {
        switch self {
        case .missingTargetApproveAddress: return 100001001
        case .wrongRemoteState: return 100001001
        }
    }
}

extension VisaUserWalletModel.ModelError: TangemError {
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
