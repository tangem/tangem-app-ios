//
//  WCURIResponse.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCURIResponse: Codable {
    let success: Bool
    let wcUri: String
    let network: String
    let timestamp: String
    let processingTime: String
}
