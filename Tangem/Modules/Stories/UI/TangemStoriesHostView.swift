//
//  TangemStoriesHostView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import enum TangemStories.TangemStory

struct TangemStoriesHostView: View {
    @ObservedObject var viewModel: TangemStoriesViewModel
    let animation: Animation

    init(viewModel: TangemStoriesViewModel, animation: Animation) {
        self.viewModel = viewModel
        self.animation = animation
    }

    var body: some View {
        ZStack {
            dimmingBackground(viewModel.state != nil)
            storiesHostView(viewModel)
        }
        .animation(animation, value: viewModel.state != nil)
    }

    @ViewBuilder
    private func dimmingBackground(_ isPresented: Bool) -> some View {
        if isPresented {
            Color.black
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private func storiesHostView(_ viewModel: TangemStoriesViewModel) -> some View {
        if let state = viewModel.state {
            StoriesHostView(
                viewModel: state.storiesHostViewModel,
                storyViews: state.storiesHostViewModel.storyViewModels.map { storyViewModel in
                    StoryView(
                        viewModel: storyViewModel,
                        pageViews: Self.makePages(for: state.activeStory, using: state.storiesHostViewModel).map(StoryPageView.init)
                    )
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private static func makePages(for story: TangemStory, using viewModel: StoriesHostViewModel) -> [any View] {
        switch story {
        case .swap:
            [
                // [REDACTED_TODO_COMMENT]
            ]
        }
    }
}
