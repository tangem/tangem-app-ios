//
// SuiError.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiError {
    enum CodingError: Error {
        case failedEncoding
        case failedDecoding
    }
}
