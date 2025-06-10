//
//  VisaPaymentAccountError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum VisaPaymentAccountError: String, LocalizedError {
    case cardNotRegisteredToAccount
    case cardIsNotActivated
}
