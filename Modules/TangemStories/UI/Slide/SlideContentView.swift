//
//  SlideContentView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct SlideContentView: View {
    @ObservedObject var vm: SlidePlayerViewModel

    private var contentMode: StoryContentMode { vm.slide.asset.contentMode }

    var body: some View {
        switch vm.slide.asset.type {
        case .image:
            SlideImageView(url: vm.slide.asset.url, contentMode: contentMode)
        case .lottie:
            // Poster shows through until the animation loads, mirroring the video path.
            ZStack {
                SlideImageView(url: vm.slide.asset.posterURL, contentMode: contentMode)

                LottieSlideView(
                    animation: vm.animation,
                    contentMode: contentMode,
                    slideDurationMs: vm.slide.asset.durationMs,
                    progress: vm.progress
                )
            }
        case .video:
            // Poster shows through the transparent player layer until the first frame renders,
            // so an unbuffered remote video never flashes a black screen.
            ZStack {
                SlideImageView(url: vm.slide.asset.posterURL, contentMode: contentMode)

                VideoPlayerView(player: vm.player, contentMode: contentMode == .cover ? .fill : .fit)
            }
        }
    }
}
