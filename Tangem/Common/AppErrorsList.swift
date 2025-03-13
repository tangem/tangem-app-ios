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
extension VisaOnboardingViewModel.OnboardingError: TangemError {
    var errorCode: Int {
        switch self {
        case .missingTargetApproveAddress: return 100001001
        case .wrongRemoteState: return 100001001
        }
    }
}
