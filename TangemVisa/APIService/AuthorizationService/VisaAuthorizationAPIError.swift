//
//  VisaAuthorizationAPIError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaAuthorizationAPIError: Decodable, LocalizedError {
    public let error: String
    public let errorDescription: String?
}
