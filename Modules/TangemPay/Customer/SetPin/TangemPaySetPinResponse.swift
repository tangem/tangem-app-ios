//
//  TangemPayPinResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPaySetPinResponse: Decodable {
    public let result: Result

    public enum Result: String, Decodable {
        case success = "SUCCESS"
        case pinTooWeak = "PIN_TOO_WEAK"
        case decryptionError = "DECRYPTION_ERROR"
        case unknownError = "UNKNOWN_ERROR"
    }
}
