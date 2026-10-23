//
//  SwapReceiveTokenResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol SwapReceiveTokenResolver {
    var initialReceive: LoadingResult<SendReceiveToken, any Error> { get }

    func resolveReceive(for source: SendSwapableToken?) async throws -> SendReceiveToken
}

// MARK: - Resolved

extension SwapReceiveTokenResolver where Self == ResolvedSwapReceiveTokenResolver {
    static func resolved(_ receive: SendReceiveToken) -> ResolvedSwapReceiveTokenResolver {
        ResolvedSwapReceiveTokenResolver(token: receive)
    }
}

// MARK: - User selection

extension SwapReceiveTokenResolver where Self == UserSelectionSwapTokenResolver {
    static var userSelection: UserSelectionSwapTokenResolver {
        UserSelectionSwapTokenResolver()
    }
}
