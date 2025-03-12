//
//  VisaAccessCodeValidationError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum VisaAccessCodeValidationError: Int, TangemError {
    case accessCodeIsTooShort = 1

    public var subsystemCode: Int {
        VisaSubsystem.accessCodeValidation.rawValue
    }
}
