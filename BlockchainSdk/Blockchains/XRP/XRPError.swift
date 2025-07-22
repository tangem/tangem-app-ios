//
//  XRPError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum XRPError: LocalizedError {
    case failedLoadUnconfirmed
    case failedLoadReserve
    case failedLoadInfo
    case missingReserve
    case distinctTagsFound
    case invalidAmount
    case invalidAddress
    case checksumFails
    case invalidSeed
    case invalidPrivateKey
    case invalidBufferSize
    case open(Int32)
    case read(Int32)
}
