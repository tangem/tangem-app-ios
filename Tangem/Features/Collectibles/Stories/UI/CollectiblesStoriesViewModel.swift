//
//  CollectiblesStoriesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

@MainActor
final class CollectiblesStoriesViewModel: ObservableObject {
    // MARK: - Properties

    private let slides: [CollectiblesStoriesView.Slide]
    private let engine: any CollectiblesStoriesEngine

    private var isOnLastSlide: Bool {
        currentSlideIndex == slides.count - 1
    }

    var currentSlide: CollectiblesStoriesView.Slide {
        slides[currentSlideIndex]
    }

    var slidesCount: Int {
        slides.count
    }

    // MARK: - Publishers

    @Published private(set) var currentSlideIndex = 0
    @Published private(set) var currentSlideProgress: CGFloat = 0
    @Published private(set) var isFinished = false

    // MARK: - Init

    init(
        slides: [CollectiblesStoriesView.Slide],
        engine: @MainActor (StoryV2) -> any CollectiblesStoriesEngine
    ) {
        self.slides = slides
        self.engine = engine(.localCollectiblesOnboarding(slides: slides))
    }

    // MARK: - Methods

    func run() async {
        engine.start()

        await withTaskGroup(of: Void.self) { [weak self, engine] group in
            group.addTask { @MainActor in
                for await slideIndex in await engine.slideIndexUpdates {
                    self?.currentSlideIndex = slideIndex
                }
            }

            group.addTask { @MainActor in
                for await slideProgress in await engine.slideProgressUpdates {
                    self?.currentSlideProgress = slideProgress
                }
            }
        }
    }

    func onForwardTap() {
        guard !isOnLastSlide else { return }

        engine.showNextSlide()
    }

    func onBackwardTap() {
        engine.showPreviousSlide()
    }

    func onPressingChanged(_ isPressing: Bool) {
        engine.setPaused(isPressing)
    }

    func onContinueTap() {
        guard !isOnLastSlide else {
            engine.finish()
            isFinished = true
            return
        }

        engine.showNextSlide()
    }

    func onCloseTap() {
        engine.close()
        isFinished = true
    }
}

private extension StoryV2 {
    static func localCollectiblesOnboarding(slides: [CollectiblesStoriesView.Slide], id: String = "collectibles_onboarding") -> Self {
        StoryV2(
            id: id,
            endBehavior: .finish,
            slides: slides.enumerated().map { index, slide in
                SlideV2(
                    id: "\(id)_\(index)",
                    order: index,
                    title: slide.title,
                    subtitle: slide.subtitle,
                    asset: AssetV2(type: .image, durationMs: 8000, url: nil)
                )
            },
            origin: .bundled
        )
    }
}
