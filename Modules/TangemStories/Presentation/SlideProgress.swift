//
//  SlideProgress.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Playback progress ticks at 60 Hz; it lives apart from `SlidePlayerViewModel` so per-tick
/// updates invalidate only the progress bar, not every view observing the slide.
@MainActor
public final class SlideProgress: ObservableObject {
    @Published public internal(set) var value: Double = 0
}
