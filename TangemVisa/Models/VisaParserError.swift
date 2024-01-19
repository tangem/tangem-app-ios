//
//  VisaParserError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaParserError: Error {
    case addressResponseDoesntContainAddress
    case noValidAddress
    case limitsResponseWrongLength
    case limitWrongLength
    case failedToParseLimitAmount
}
