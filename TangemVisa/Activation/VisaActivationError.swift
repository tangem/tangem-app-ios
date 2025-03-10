//
//  VisaActivationError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum VisaActivationError: TangemError {
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

    public var errorDescription: String? {
        switch self {
        case .notImplemented: return "Not implemented"
        case .missingAccessCode: return "Missing access code"
        case .missingAccessToken: return "Missing access token. Please authorize with your Visa card"
        case .missingActiveCardSession: return "Failed to find active NFC session"
        case .missingCustomerInformationInAccessToken: return "Missing essential data for Visa Activation. Contact to support"
        case .wrongCard: return "Wrong card tapped"
        case .missingOrderDataToSign: return "Failed to find order for account activation"
        case .missingWallet: return "Failed to find wallet on card"
        case .missingRootOTP: return "Failed to find root OTP"
        case .taskMissingDelegate: return "Activation task wasn't setup properly"
        case .missingOTPRepository: return "Failed to find OTP repository"
        case .alreadyActivated: return "Card already activated"
        case .accessCodeAlreadySet: return "Access code already set, wrong task used for activation"
        case .blockedForActivation: return "This card cannot be activated. Please contact support for more information."
        case .invalidActivationState: return "Invalid activation state. Please close activation proccess and scan card again"
        case .missingDerivationPath: return "Something went wrong. Please contact support"
        case .missingActivationStatusInfo: return "Missing activation status info. Please contact support"
        case .missingWalletAddressInInput: return "Missing wallet address in input. Please contact support"
        case .missingActivationInput: return "Missing activation input. Please contact support"
        case .underlyingError(let error):
            return "Underlying Visa Activation Error: \(error.localizedDescription)"
        }
    }

    public var subsystemCode: Int {
        if case .underlyingError(let error) = self, let tangemError = error as? TangemError {
            return tangemError.subsystemCode
        }

        return VisaSubsystem.activation.rawValue
    }

    public var errorCode: Int {
        switch self {
        case .notImplemented: return 1
        case .missingAccessCode: return 2
        case .missingAccessToken: return 3
        case .missingActiveCardSession: return 4
        case .missingCustomerInformationInAccessToken: return 5
        case .wrongCard: return 6
        case .missingOrderDataToSign: return 7
        case .missingWallet: return 8
        case .missingRootOTP: return 9
        case .taskMissingDelegate: return 10
        case .missingOTPRepository: return 11
        case .alreadyActivated: return 12
        case .accessCodeAlreadySet: return 13
        case .blockedForActivation: return 14
        case .invalidActivationState: return 15
        case .missingDerivationPath: return 16
        case .missingActivationStatusInfo: return 17
        case .missingWalletAddressInInput: return 18
        case .missingActivationInput: return 19
        case .underlyingError(let error):
            if let tangemError = error as? TangemError {
                return tangemError.errorCode
            }

            return 20
        }
    }
}

public enum VisaAccessCodeValidationError: Int, TangemError {
    case accessCodeIsTooShort

    public var subsystemCode: Int {
        VisaSubsystem.accessCodeValidation.rawValue
    }
}
