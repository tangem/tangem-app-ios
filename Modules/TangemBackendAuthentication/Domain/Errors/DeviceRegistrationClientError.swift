//
//  DeviceRegistrationClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum DeviceRegistrationClientError: Error {
    case requestNonceFailed(underlying: any Error)
    case registerFailed(underlying: any Error)
    case alreadyRegistered
}
