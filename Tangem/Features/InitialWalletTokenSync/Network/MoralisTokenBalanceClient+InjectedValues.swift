//
//  MoralisTokenBalanceClient+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

extension InjectedValues {
    var moralisTokenBalanceClient: MoralisTokenBalanceClient {
        get { Self[MoralisTokenBalanceClientKey.self] }
        set { Self[MoralisTokenBalanceClientKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct MoralisTokenBalanceClientKey: InjectionKey {
    static var currentValue: MoralisTokenBalanceClient = {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 3)
        let commonClient = CommonMoralisTokenBalanceClient()
        return RateLimitedMoralisTokenBalanceClient(client: commonClient, queue: queue, retryBackoff: .seconds(1))
    }()
}
