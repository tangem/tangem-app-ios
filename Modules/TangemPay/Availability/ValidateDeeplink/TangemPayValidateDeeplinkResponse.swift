//
//  TangemPayValidateDeeplinkResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayValidateDeeplinkResponse: Decodable {
    public enum Status: String, Decodable {
        case valid = "VALID"
        case invalid = "INVALID"
    }

    public let status: Status
}
