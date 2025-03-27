//
//  VisaActivationError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum VisaActivationError {
    case notImplemented
    case missingAccessCode
    case missingAccessToken
    case missingActiveCardSession
    case missingCustomerInformationInAccessToken
    case wrongCard
    case missingOrderDataToSign
    case missingWallet
    case missingRootOTP
    case taskMissingDelegate
    case missingOTPRepository
    case alreadyActivated
    case accessCodeAlreadySet
    case blockedForActivation
    case invalidActivationState
    case missingDerivationPath
    case missingActivationStatusInfo
    case missingWalletAddressInInput
    case missingActivationInput
    case underlyingError(Error)
}
