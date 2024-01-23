//
//  VisaParserError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaParserError: LocalizedError {
    case addressResponseDoesntContainAddress
    case noValidAddress
    case limitsResponseWrongLength
    case limitWrongLength
    case failedToParseLimitAmount

    public var errorDescription: String? {
        switch self {
        case .addressResponseDoesntContainAddress:
            return "Address response doesn't contain address"
        case .noValidAddress:
            return "Parsed address is not valid"
        case .limitsResponseWrongLength:
            return "Wrong length for Limits response"
        case .limitWrongLength:
            return "Single limit doesn't contain all necessary info"
        case .failedToParseLimitAmount:
            return "Single limit doesn't contain all mandatory amounts"
        }
    }
}
