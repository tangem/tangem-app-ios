//
//  WelcomeStoryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemStories

struct WelcomeStoryView: View {
    @ObservedObject var viewModel: WelcomeStoryPresentationViewModel

    var body: some View {
        StoryPlayerView(vm: viewModel.player)
    }
}
