//
//  CommonGachaStoriesEngine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import TangemStories

@MainActor
final class CommonGachaStoriesEngine {
    private let player: StoryPlayerViewModel
    private let finishSubject: PassthroughSubject<Void, Never>

    init(story: StoryV2) {
        let finishSubject = PassthroughSubject<Void, Never>()
        self.finishSubject = finishSubject

        player = StoryPlayerViewModel(story: story) { _, _ in
            finishSubject.send()
        }
    }
}

// MARK: - GachaStoriesEngine

extension CommonGachaStoriesEngine: GachaStoriesEngine {
    var slideIndexPublisher: AnyPublisher<Int, Never> {
        player.$currentIndex.eraseToAnyPublisher()
    }

    var slideProgressPublisher: AnyPublisher<CGFloat, Never> {
        player.$current.flatMapLatest { $0.$progress }.map { CGFloat($0) }.eraseToAnyPublisher()
    }

    var storiesFinishedPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func start() {
        player.start()
    }

    func showNextSlide() {
        player.tapForward()
    }

    func showPreviousSlide() {
        player.tapBackward()
    }

    func setPaused(_ isPaused: Bool) {
        isPaused ? player.pause() : player.resume()
    }
}
