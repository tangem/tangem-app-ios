//
//  KoinosError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum KoinosError: Error {
    case unableToParseParams
    case unableToDecodeChainID
    case contractIDIsMissing
    case failedToMapKoinosDTO
}
