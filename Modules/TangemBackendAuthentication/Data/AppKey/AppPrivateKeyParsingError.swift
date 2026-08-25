//
//  AppPrivateKeyParsingError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum AppPrivateKeyParsingError: Error {
    case invalidBase64Encoding
    case invalidKeyFormat(underlying: any Error)
}
