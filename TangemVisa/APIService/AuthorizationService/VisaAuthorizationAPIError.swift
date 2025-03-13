//
//  VisaAuthorizationAPIError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct VisaAuthorizationAPIError: Decodable {
    public let error: String
    public let errorDescription: String?
}
