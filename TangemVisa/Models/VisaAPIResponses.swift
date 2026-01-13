//
//  VisaAPIResponses.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct VisaAPIResponse<T: Decodable>: Decodable {
    let result: T
}

struct VisaAPIErrorResponse: Decodable {
    let error: VisaAPIError
}

public struct VisaAPIError: Error, Decodable, Sendable {
    public let code: Int
    public let name: String
    public let message: String

    public var errorDescription: String? {
        return """
        Name: \(name)
        Code: \(errorCode)
        Message: \(message)
        """
    }
}
