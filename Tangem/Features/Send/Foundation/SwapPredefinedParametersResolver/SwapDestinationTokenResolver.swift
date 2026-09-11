//
//  SwapDestinationTokenResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Picks the swap destination to pair with a given source. `SwapModel` consults it on every source
/// pick, so the destination it returns replaces the current one.
protocol SwapDestinationTokenResolver: AnyObject {
    func resolveDestination(for source: SendSwapableToken) -> SendReceiveToken
}
