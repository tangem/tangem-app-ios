//
//  WireMockError.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WireMockError: Error {
    case httpError(URLResponse)
    case invalidResponse
    case scenarioNotFound(String)

    var localizedDescription: String {
        switch self {
        case .httpError(let response):
            if let httpResponse = response as? HTTPURLResponse {
                return "HTTP Error: \(httpResponse.statusCode)"
            }
            return "HTTP Error: Unknown"
        case .invalidResponse:
            return "Invalid response from WireMock"
        case .scenarioNotFound(let name):
            return "Scenario '\(name)' not found"
        }
    }
}
