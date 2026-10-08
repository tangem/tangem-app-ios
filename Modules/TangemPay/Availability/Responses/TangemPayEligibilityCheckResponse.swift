//
//  TangemPayEligibilityCheckResponse.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayEligibilityCheckResponse: Decodable {
    public let available: Bool
    public let countryCode: String
    public let regionCode: String?
}
