//
//  TangemPay+UniversalError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

public protocol TangemPayError: UniversalError {}

extension TangemPayKYCService.TangemPayKYCServiceError: TangemPayError {
    public var errorCode: Int {
        switch self {
        case .sdkIsNotReady:
            104013000
        case .alreadyPresent:
            104013001
        }
    }
}

extension RainCryptoUtilities.RainCryptoUtilitiesError: TangemPayError {
    public var errorCode: Int {
        switch self {
        case .invalidSecretKey, .invalidDecryptedPinBlock:
            104014001
        case .invalidBase64EncodedPublicKey:
            104014002
        case .failedToCreateSecKey:
            104014003
        case .failedToEncryptDataWithPublicKey:
            104014004
        case .invalidBase64EncodedSecret:
            104014005
        case .invalidBase64EncodedIv:
            104014006
        case .aesGCM:
            104014007
        case .invalidDecryptedData:
            104014008
        case .invalidSecretToEncrypt:
            104014009
        case .failedToGenerateRandomBytes:
            104014010
        }
    }
}
