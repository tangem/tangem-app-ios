//
//  StoryPlayerViewModel+GachaStoriesEngine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import TangemStories

extension StoryPlayerViewModel: GachaStoriesEngine {
    var slideIndexPublisher: AnyPublisher<Int, Never> {
        $currentIndex.eraseToAnyPublisher()
    }

    var slideProgressPublisher: AnyPublisher<CGFloat, Never> {
        $current.flatMapLatest { $0.$progress }.map { CGFloat($0) }.eraseToAnyPublisher()
    }

    func showNextSlide() {
        tapForward()
    }

    func showPreviousSlide() {
        tapBackward()
    }

    func setPaused(_ isPaused: Bool) {
        isPaused ? pause() : resume()
    }
}
