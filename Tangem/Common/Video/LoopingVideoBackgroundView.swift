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

    var body: some View {
        VideoPlayerView(player: viewModel.player)
            .background(Color.black)
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
    }
}
