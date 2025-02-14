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

    var body: some View {
        ZStack {
            dimmingBackground(isPresented: viewModel.state != nil)
            storiesHostView(viewModel)
        }
        .animation(Constants.animation, value: viewModel.state)
    }

    @ViewBuilder
    private func dimmingBackground(isPresented: Bool) -> some View {
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
        case .swap(let swapStoryData):
            swapStoryData
                .pagesKeyPaths
                .map { pageKeyPath in
                    let page = swapStoryData[keyPath: pageKeyPath]
                    return SwapStoryPageView(page: page)
                }
        }
    }
}

extension TangemStoriesHostView {
    enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static let animation = Animation.easeInOut(duration: Self.animationDuration)
    }
}
