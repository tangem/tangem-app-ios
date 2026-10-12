//
//  LottieSlideView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Lottie
import SwiftUI

/// Renders the slide's animation as a still frame driven by `SlideProgress`: the picture, the
/// progress bar and the haptics follow one clock, so pause, restart and completion can't drift.
struct LottieSlideView: View {
    let animation: LottieAnimation?
    let contentMode: StoryContentMode
    let slideDurationMs: Int
    @ObservedObject var progress: SlideProgress

    var body: some View {
        LottieView(animation: animation)
            .configure { view in
                // Transparent so the poster underneath stays visible until the animation loads.
                view.backgroundColor = .clear
                view.contentMode = contentMode == .cover ? .scaleAspectFill : .scaleAspectFit
            }
            .playbackMode(.paused(at: .progress(animationProgress)))
            .resizable()
    }

    /// The animation keeps its authored speed: a slide longer than the animation holds the last
    /// frame rather than playing it in slow motion, and a shorter one simply cuts it off.
    private var animationProgress: AnimationProgressTime {
        guard let animation, animation.duration > 0 else { return progress.value }

        let slideDuration = Double(slideDurationMs) / 1000
        return min(progress.value * slideDuration / animation.duration, 1)
    }
}
