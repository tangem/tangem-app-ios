//
//  StoriesV2DemoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemStories

struct StoriesV2DemoView: View {
    @ObservedObject var viewModel: StoriesV2DemoViewModel

    var body: some View {
        List {
            Section {
                Button("Sample story (local)") { viewModel.openSample() }
            }
        }
        .navigationTitle("Stories V2 Demo")
        .fullScreenCover(isPresented: isPresenting) {
            if let player = viewModel.player {
                StoryPlayerView(vm: player)
            }
        }
    }

    private var isPresenting: Binding<Bool> {
        Binding(
            get: { viewModel.player != nil },
            set: { presented in if !presented { viewModel.closePlayer() } }
        )
    }
}
