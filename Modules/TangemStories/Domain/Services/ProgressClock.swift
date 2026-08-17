//
//  ProgressClock.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Drives timer-based slide progress for image / lottie / degraded video. Real video progress
/// comes from `AVPlayer`, not from this clock.
public protocol ProgressClock {
    @MainActor
    func start(interval: TimeInterval, onTick: @escaping (_ delta: TimeInterval) -> Void) -> AnyCancellable
}
