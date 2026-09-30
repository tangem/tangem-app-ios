//
//  StoryPlayerViewModel+CollectiblesStoriesEngine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import TangemLocalization
import TangemStories

extension StoryPlayerViewModel: CollectiblesStoriesEngine {
    var slideIndexPublisher: AnyPublisher<Int, Never> {
        $currentIndex.eraseToAnyPublisher()
    }

    var slideProgressPublisher: AnyPublisher<CGFloat, Never> {
        $current.flatMapLatest { $0.progress.$value }.map { CGFloat($0) }.eraseToAnyPublisher()
    }

    func showNextSlide() {
        tapForward()
    }

    func showPreviousSlide() {
        tapBackward()
    }

    func setPaused(_ isPaused: Bool) {
        setPaused(isPaused, for: .hold)
    }

    func close() {
        closeButtonTapped()
    }

    func finish() {
        finish(for: .collectiblesBrowsePacks)
    }
}

// MARK: - Actions

private extension StoryActionV2 {
    static let collectiblesBrowsePacks = StoryActionV2(
        id: "browse_packs",
        label: Localization.collectiblesStoriesBrowsePacksButton,
        style: .primary,
        target: .close
    )
}
