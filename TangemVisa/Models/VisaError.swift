//
//  VisaError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum VisaError: TangemError {
    case failedToCreateDerivation
    case failedToCreateAddress(Error)

    public var errorDescription: String? {
        switch self {
        case .failedToCreateDerivation:
            return "Derivation error. Please contact support"
        case .failedToCreateAddress:
            return "Address creation error. Please contact support"
        }
    }

    public var subsystemCode: Int {
        VisaSubsystem.common.rawValue
    }

    public var errorCode: Int {
        switch self {
        case .failedToCreateDerivation:
            return 1
        case .failedToCreateAddress:
            return 2
        }
    }
}
