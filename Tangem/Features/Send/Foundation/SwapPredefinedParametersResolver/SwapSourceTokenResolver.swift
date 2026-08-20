//
//  SwapSourceTokenResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Picks the initial swap source token once wallet balances settle. `SwapModel` consults it during
/// initial loading and drops the result if the user picked a source in the meantime.
protocol SwapSourceTokenResolver: AnyObject {
    func resolve() async -> SendSwapableToken?
}
