//
//  TangemPayWaitlistService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayWaitlistService {
    func joinWaitlist(
        _ request: TangemPayJoinWaitlistRequest,
        idempotencyKey: String
    ) async throws(TangemPayWaitlistError) -> TangemPayJoinWaitlistResponse
}

public enum TangemPayWaitlistError: Error {
    case invalidEmail
    case failed(TangemPayAPIServiceError)
}
