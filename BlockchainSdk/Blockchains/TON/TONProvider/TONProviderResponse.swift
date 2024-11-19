//
//  TONProviderResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Base TON provider response
struct TONProviderResponse<R: Decodable>: Decodable {
    /// Success status
    let ok: Bool

    /// Decodable result
    let result: R

    /// Description error
    let error: String?

    /// Response code (Not transport)
    let code: Int?
}
