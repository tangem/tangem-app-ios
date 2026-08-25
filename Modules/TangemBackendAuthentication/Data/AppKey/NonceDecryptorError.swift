//
//  NonceDecryptorError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum NonceDecryptorError: Error {
    case appPrivateKeyParsingFailed(AppPrivateKeyParsingError)
    case decryptFailed(underlying: any Error)
}
