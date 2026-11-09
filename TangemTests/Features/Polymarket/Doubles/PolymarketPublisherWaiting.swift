//
//  PolymarketPublisherWaiting.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

extension Publisher where Failure == Never {
    @MainActor
    @discardableResult
    func firstValue(where isMatching: @escaping (Output) -> Bool) async -> Output {
        var subscription: AnyCancellable?

        let value = await withCheckedContinuation { (continuation: CheckedContinuation<Output, Never>) in
            subscription = first(where: isMatching).sink { continuation.resume(returning: $0) }
        }

        subscription?.cancel()
        return value
    }
}
