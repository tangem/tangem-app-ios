//
//  GachaStoriesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

@MainActor
final class GachaStoriesViewModel: ObservableObject {
    // MARK: - Properties

    private let slides: [GachaStoriesView.Slide]
    private let engine: any GachaStoriesEngine

    private weak var routable: (any GachaStoriesRoutable)?

    var currentSlide: GachaStoriesView.Slide {
        slides[currentSlideIndex]
    }

    var slidesCount: Int {
        slides.count
    }

    // MARK: - Publishers

    @Published private(set) var currentSlideIndex = 0
    @Published private(set) var currentSlideProgress: CGFloat = 0

    // MARK: - Init

    init(
        slides: [GachaStoriesView.Slide],
        engine: @MainActor (StoryV2) -> any GachaStoriesEngine,
        routable: (any GachaStoriesRoutable)?
    ) {
        self.slides = slides
        self.engine = engine(.localGachaOnboarding(slides: slides))
        self.routable = routable
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

            group.addTask { @MainActor in
                await engine.storiesFinished()

                // A cancelled `storiesFinished()` returns like a finished one — don't take it for a finish.
                guard !Task.isCancelled else { return }

                self?.routable?.openMain()
            }
        }
    }

    func onForwardTap() {
        engine.showNextSlide()
    }

    func onBackwardTap() {
        engine.showPreviousSlide()
    }

    func onPressingChanged(_ isPressing: Bool) {
        engine.setPaused(isPressing)
    }

    func onContinueTap() {
        guard currentSlideIndex < slides.count - 1 else {
            routable?.openMain()
            return
        }

        engine.showNextSlide()
    }

    func onCloseTap() {
        routable?.openMain()
    }
}

extension GachaStoriesViewModel {
    convenience init(routable: (any GachaStoriesRoutable)?) {
        self.init(
            slides: GachaStoriesView.Slide.content,
            engine: CommonGachaStoriesEngine.init,
            routable: routable
        )
    }
}

private extension StoryV2 {
    static func localGachaOnboarding(slides: [GachaStoriesView.Slide], id: String = "gacha_onboarding") -> Self {
        StoryV2(
            id: id,
            version: 1,
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
