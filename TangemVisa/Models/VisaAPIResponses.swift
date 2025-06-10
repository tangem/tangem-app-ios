//
//  VisaAPIError.swift
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

struct VisaAPIError: Error, Decodable {
    let code: Int
    let name: String
    let message: String

    var errorDescription: String? {
        return """
        Name: \(name)
        Code: \(errorCode)
        Message: \(message)
        """
    }
}
