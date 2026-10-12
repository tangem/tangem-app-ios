//
//  JointAccountActivationConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct JointAccountActivationConfig {
    let cryptoAccountId: String
    /// Signed exactly as the account was created with: activating confirms those terms rather than restating them.
    let signedConfig: JointAccountSignedConfig
    /// The address the app worked out for itself and matched against the announced one — see
    /// `JointAccountSafeAddressVerifier`.
    let safeAddress: String
    /// The address of the slot this wallet signs with, which the endpoint accepts only from the creator's.
    let creatorAddress: String
    let derivationIndex: Int
}
