//
//  StoryAnimationLoader.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Lottie

protocol StoryAnimationLoading: Sendable {
    func animation(at url: URL) async -> LottieAnimation?
}

struct StoryAnimationLoader: StoryAnimationLoading {
    /// The shared cache keeps a story reopened within a session from re-parsing the same JSON.
    func animation(at url: URL) async -> LottieAnimation? {
        await LottieAnimation.loadedFrom(url: url, animationCache: LottieAnimationCache.shared)
    }
}
