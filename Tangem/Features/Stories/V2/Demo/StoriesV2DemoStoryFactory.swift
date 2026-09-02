//
//  StoriesV2DemoStoryFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

/// Builds the local sample content for the Stories V2 demo screen.
struct StoriesV2DemoStoryFactory {
    func makeSampleStory() -> StoryV2 {
        StoryV2(
            id: Constants.storyID,
            placements: [Constants.placement],
            endBehavior: .finish,
            actions: [
                StoryActionV2(
                    id: Constants.closeActionID,
                    label: "Got it",
                    style: .primary,
                    target: .close
                ),
            ],
            slides: makeSlides(),
            origin: .bundled
        )
    }

    private func makeSlides() -> [SlideV2] {
        slideCopy.enumerated().map { index, copy in
            let order = index + 1
            return SlideV2(
                id: "\(Constants.storyID)_slide_\(order)",
                order: order,
                title: copy.title,
                subtitle: copy.subtitle,
                asset: AssetV2(type: .image, durationMs: Constants.slideDurationMs, url: nil)
            )
        }
    }

    private let slideCopy: [SlideCopy] = [
        SlideCopy(title: "Stories V2", subtitle: "Local sample — no backend needed"),
        SlideCopy(title: "Segmented progress", subtitle: "Tap the right/left third to navigate"),
        SlideCopy(title: "Long-press to pause", subtitle: "Swipe down or tap Got it to close"),
    ]

    private struct SlideCopy {
        let title: String
        let subtitle: String
    }
}

private extension StoriesV2DemoStoryFactory {
    enum Constants {
        static let storyID = "sample"
        static let placement = "main_upgrade"
        static let closeActionID = "close"
        static let slideDurationMs = 3000
    }
}
