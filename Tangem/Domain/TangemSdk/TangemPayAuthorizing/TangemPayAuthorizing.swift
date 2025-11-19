//
//  TangemPayAuthorizing.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemVisa

protocol TangemPayAuthorizing: AnyObject {
    func authorize(authorizationService: VisaAuthorizationService) async throws -> TangemPayAuthorizingResponse
}

struct TangemPayAuthorizingResponse {
    public let tokens: VisaAuthorizationTokens
    public let derivationResult: [Data: DerivedKeys]
}
