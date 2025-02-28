//
//  StoriesHostView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct StoriesHostView: View {
    @ObservedObject var viewModel: StoriesHostViewModel
    let storyViews: [StoryView]

    init(viewModel: StoriesHostViewModel, storyViews: [StoryView]) {
        self.viewModel = viewModel
        self.storyViews = storyViews
    }

    var body: some View {
        TabView(selection: $viewModel.visibleStoryIndex) {
            ForEach(storyViews.indexed(), id: \.0) { index, storyView in
                ZStack(alignment: .top) {
                    storyView
                        .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.default, value: viewModel.visibleStoryIndex)
        .allowsHitTesting(viewModel.allowsHitTesting)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
