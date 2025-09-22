//
//  ValidateDeeplinkResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct ValidateDeeplinkResponse: Decodable {
    public enum Status: String, Decodable {
        case valid
        case invalid
    }

    public let status: Status
}
