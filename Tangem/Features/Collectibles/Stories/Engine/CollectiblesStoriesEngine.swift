//
//  CollectiblesStoriesEngine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import struct CoreGraphics.CGFloat

@MainActor
protocol CollectiblesStoriesEngine: AnyObject {
    var slideIndexPublisher: AnyPublisher<Int, Never> { get }
    var slideProgressPublisher: AnyPublisher<CGFloat, Never> { get }

    func start()
    func showNextSlide()
    func showPreviousSlide()
    func setPaused(_ isPaused: Bool)
    func close()
    func finish()
}

// MARK: - Async API

extension CollectiblesStoriesEngine {
    var slideIndexUpdates: AsyncStream<Int> {
        get async { await slideIndexPublisher.removeDuplicates().values }
    }

    var slideProgressUpdates: AsyncStream<CGFloat> {
        get async { await slideProgressPublisher.removeDuplicates().values }
    }
}
