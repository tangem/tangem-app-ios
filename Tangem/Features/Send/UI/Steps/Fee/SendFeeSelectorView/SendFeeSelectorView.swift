//
//  SendFeeSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendFeeSelectorView: View {
    // MARK: - View Model

    @ObservedObject
    var viewModel: SendFeeSelectorViewModel

    // MARK: - View Body

    var body: some View {
        content
            .animation(.contentFrameUpdate, value: viewModel.state)
    }

    // MARK: - Sub Views

    private var content: some View {
        VStack(spacing: .zero) {
            header

            topContent
                .padding(.bottom, 16)

            FeeSelectorView(viewModel: viewModel.feeSelectorViewModel)
                .transition(.content)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    private var header: some View {
        BottomSheetHeaderView(
            title: viewModel.state.title,
            leading: { leadingHeaderButton },
            trailing: { trailingHeaderButton }
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .transition(.content)
    }

    @ViewBuilder
    private var topContent: some View {
        if !viewModel.state.description.characters.isEmpty {
            Text(viewModel.state.description)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openURL()
                    return .handled
                })
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var leadingHeaderButton: some View {
        if viewModel.state.headerButtonAction.isBack {
            CircleButton.back(action: viewModel.userDidTapBackButton)
        }
    }

    @ViewBuilder
    private var trailingHeaderButton: some View {
        if viewModel.state.headerButtonAction.isClose {
            CircleButton.close(action: viewModel.userDidTapDismissButton)
        }
    }
}

// MARK: - Animation

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}
