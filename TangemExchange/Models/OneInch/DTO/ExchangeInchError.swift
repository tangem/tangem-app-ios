//
//  ExchangeInchError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeInchError: Error {
    case unknownError(statusCode: Int?)
    case serverError(withError: Error)
    case parsedError(withInfo: InchError)
    case decodeError(error: Error)
}

public struct InchError: Decodable, Error {
    public let statusCode: Int
    public let error: String
    public let description: String
    public let requestId: String

    internal init(
        statusCode: Int,
        error: String = "",
        description: String = "",
        requestId: String = ""
    ) {
        self.statusCode = statusCode
        self.error = error
        self.description = description
        self.requestId = requestId
    }
}
