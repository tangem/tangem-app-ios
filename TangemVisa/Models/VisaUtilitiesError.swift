//
//  VisaUtilitiesError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum VisaUtilitiesError {
    case failedToCreateDerivation
    case failedToCreateAddress(Error)
    case failedToCreateEIP191Message(content: String)
}
