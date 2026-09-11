//
//  RealProgressClock.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public final class RealProgressClock: ProgressClock {
    public init() {}

    @MainActor
    public func start(interval: TimeInterval, onTick: @escaping (TimeInterval) -> Void) -> AnyCancellable {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in onTick(interval) }
    }
}
