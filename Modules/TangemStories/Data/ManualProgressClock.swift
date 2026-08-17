//
//  ManualProgressClock.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Test-support: drives `onTick` deterministically via `tick()` / `advance(by:)`.
@MainActor
public final class ManualProgressClock: ProgressClock {
    private var onTick: ((TimeInterval) -> Void)?
    public private(set) var interval: TimeInterval = 0

    public init() {}

    public func start(interval: TimeInterval, onTick: @escaping (TimeInterval) -> Void) -> AnyCancellable {
        self.interval = interval
        self.onTick = onTick
        return AnyCancellable {}
    }

    public func tick(_ count: Int = 1) {
        for _ in 0 ..< count {
            onTick?(interval)
        }
    }

    public func advance(by seconds: TimeInterval) {
        guard interval > 0 else { return }
        tick(Int(seconds / interval))
    }
}
