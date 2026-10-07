//
//  WelcomeV2VideoBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct WelcomeV2VideoBackgroundView: View {
    @ObservedObject var viewModel: WelcomeV2VideoBackgroundViewModel

    var body: some View {
        VideoPlayerView(player: viewModel.player)
            .background(Color.black)
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
    }
}
