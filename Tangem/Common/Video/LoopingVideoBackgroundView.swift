//
//  LoopingVideoBackgroundView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct LoopingVideoBackgroundView: View {
    @ObservedObject var viewModel: LoopingVideoBackgroundViewModel
    var fitsWithBlurredBackdropWhenWide = false

    var body: some View {
        VideoPlayerView(player: viewModel.player, fitsWithBlurredBackdropWhenWide: fitsWithBlurredBackdropWhenWide)
            .background(Color.black)
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
    }
}
