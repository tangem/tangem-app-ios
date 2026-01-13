//
//  TangemPay+UniversalError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

public protocol TangemPayError: UniversalError {}

extension TangemPayKYCService.TangemPayKYCServiceError: TangemPayError {
    public var errorCode: Int {
        switch self {
        case .sdkIsNotReady:
            104013000
        case .alreadyPresent:
            104013001
        }
    }
}
