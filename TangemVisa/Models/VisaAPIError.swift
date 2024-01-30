//
//  VisaAPIError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct VisaAPIError: Decodable, LocalizedError {
    let status: Int
    let message: String
    let timestamp: String

    var errorDescription: String? {
        return """
        Status: \(status)
        Message: \(message)
        Timestamp: \(timestamp)
        """
    }
}
