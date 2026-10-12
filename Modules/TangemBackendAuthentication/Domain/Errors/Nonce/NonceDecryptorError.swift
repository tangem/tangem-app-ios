//
//  NonceDecryptorError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum NonceDecryptorError: Error {
    case invalidCipheredNonceEncoding
    case appPrivateKeyParsingFailed(AppPrivateKeyParsingError)
    case decryptFailed(underlying: any Error)
}
