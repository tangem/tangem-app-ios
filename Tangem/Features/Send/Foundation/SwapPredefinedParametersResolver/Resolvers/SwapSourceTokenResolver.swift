//
//  SwapSourceTokenResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Picks the initial swap source token once wallet balances settle. `SwapModel` consults it during
/// initial loading and drops the result if the user picked a source in the meantime.
protocol SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> { get }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken
}

// MARK: - Resolved

extension SwapSourceTokenResolver where Self == ResolvedSwapSourceTokenResolver {
    static func resolved(_ source: SendSwapableToken) -> ResolvedSwapSourceTokenResolver {
        ResolvedSwapSourceTokenResolver(token: source)
    }
}

// MARK: - User selection

extension SwapSourceTokenResolver where Self == UserSelectionSwapTokenResolver {
    static var userSelection: UserSelectionSwapTokenResolver {
        UserSelectionSwapTokenResolver()
    }
}
