//
//  UserWalletRegistrationSignerError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum UserWalletRegistrationSignerError: Error {
    case unlockCanceled
    case userWalletNeedsToBeDeleted
    case keyDerivationFailed(underlying: any Error)
    case walletKeyUnavailable(underlying: any Error)
    case signingFailed(underlying: any Error)
    case signatureMissing
    case signatureRecoveryFailed(underlying: any Error)
}
