//
//  WelcomeVideoBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct WelcomeVideoBackgroundView: View {
    @ObservedObject var viewModel: WelcomeVideoBackgroundViewModel

    var body: some View {
        VideoPlayerView(player: viewModel.player, fitsWithBlurredBackdropWhenWide: true)
            .background(Color.black)
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
    }
}
