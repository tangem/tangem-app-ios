//
//  VisaErrorsList.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Each error code must follow this format: xxxyyyzzz where
/// xxx - Feature code
/// yyy - Subsystem code
/// zzz - Specific error code
/// If you need to add new subsystem add it to list below incrementing last code.
/// `Subsystems`:
/// `001` - Common API
/// `002` - Authorization Tokens Handler
/// `003` - Activation
/// `004` - Access Code Validation
/// `005` - Authorization API
/// `006` - Paymentology PIN processing
/// `007` - Payment account responses processing
/// `008` - Card Authorization Processor
/// `009` - Common Visa
extension VisaAPIError: TangemError {
    public var errorCode: Int { 104001001 }
}

extension VisaAuthorizationTokensHandlerError: TangemError {
    public var errorCode: Int {
        switch self {
        case .authorizationTokensNotFound: return 104002001
        case .refreshTokenExpired: return 104002002
        case .missingMandatoryInfoInAccessToken: return 104002003
        case .missingAccessToken: return 104002004
        case .missingRefreshToken: return 104002005
        case .accessTokenExpired: return 104002006
        case .failedToUpdateAccessToken: return 104002007
        }
    }
}

extension VisaActivationError: TangemError {
    public var errorCode: Int {
        switch self {
        case .notImplemented: return 104003001
        case .missingAccessCode: return 104003002
        case .missingAccessToken: return 104003003
        case .missingActiveCardSession: return 104003004
        case .missingCustomerInformationInAccessToken: return 104003005
        case .wrongCard: return 104003006
        case .missingOrderDataToSign: return 104003007
        case .missingWallet: return 104003008
        case .missingRootOTP: return 104003009
        case .taskMissingDelegate: return 1040030010
        case .missingOTPRepository: return 104003011
        case .alreadyActivated: return 104003012
        case .accessCodeAlreadySet: return 104003013
        case .blockedForActivation: return 104003014
        case .invalidActivationState: return 104003015
        case .missingDerivationPath: return 104003016
        case .missingActivationStatusInfo: return 104003017
        case .missingWalletAddressInInput: return 104003018
        case .missingActivationInput: return 104003019
        case .underlyingError(let error):
            if let tangemError = error as? TangemError {
                return tangemError.errorCode
            }

            return 104003020
        }
    }
}

extension VisaAccessCodeValidationError: TangemError {
    public var errorCode: Int {
        switch self {
        case .accessCodeIsTooShort: return 104004001
        }
    }
}

extension VisaAuthorizationAPIError: TangemError {
    public var errorCode: Int { 104005001 }
}

extension PaymentologyPINCodeProcessor.PaymentologyError: TangemError {
    public var errorCode: Int {
        switch self {
        case .invalidSessionKeyFormat: return 104006001
        case .invalidRSAKeyFormat: return 104006002
        case .failedToCreateRSAKey: return 104006003
        case .failedToCreateSessionIdData: return 104006004
        case .failedToCreateSessionId: return 104006005
        case .invalidMessageFormat: return 104006006
        }
    }
}

extension VisaParserError: TangemError {
    public var errorCode: Int {
        switch self {
        case .addressResponseDoesntContainAddress: return 104007001
        case .addressesResponseHasWrongLength: return 104007002
        case .noValidAddress: return 104007003
        case .limitsResponseWrongLength: return 104007004
        case .limitWrongLength: return 104007005
        case .limitWrongSingleLimitItemsCount: return 104007006
        case .limitWrongSingleLimitAmountsCount: return 104007007
        case .notEnoughOTPData: return 104007008
        }
    }
}

extension VisaCardAuthorizationProcessorError: TangemError {
    public var errorCode: Int {
        switch self {
        case .authorizationChallengeNotFound: return 104008001
        case .invalidCardInput: return 104008001
        case .networkError(let error):
            if let tangemError = error as? TangemError {
                return tangemError.errorCode
            }

            return 104008003
        }
    }
}

extension VisaError: TangemError {
    public var errorCode: Int {
        switch self {
        case .failedToCreateDerivation: return 104009001
        case .failedToCreateAddress(let error):
            if let tangemError = error as? TangemError {
                return tangemError.errorCode
            }

            return 104009002
        }
    }
}
