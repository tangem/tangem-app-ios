//
//  VisaParserError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum VisaParserError {
    case addressResponseDoesntContainAddress
    case addressesResponseHasWrongLength
    case noValidAddress
    case limitsResponseWrongLength
    case limitWrongLength
    case limitWrongSingleLimitItemsCount
    case limitWrongSingleLimitAmountsCount
    case notEnoughOTPData
}
