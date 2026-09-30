//
//  TangemPayEligibilityCheckResponse.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayEligibilityCheckResponse: Decodable {
    public let available: Bool
    public let country: String
    public let region: String?
}
