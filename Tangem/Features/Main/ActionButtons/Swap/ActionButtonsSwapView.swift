//
//  ActionButtonsSwapView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct ActionButtonsSwapView: View {
    @ObservedObject var viewModel: ActionButtonsSwapViewModel

    var body: some View {
        selector
            .scrollDismissesKeyboard(.interactively)
            .background(Colors.Background.tertiary.ignoresSafeArea())
            .navigationTitle(Localization.commonSwap)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut, value: viewModel.destination == nil)
            .animation(.easeInOut, value: viewModel.notificationInput)
            .animation(.none, value: viewModel.source.id)
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
            }
            .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var header: some View {
        GroupedSection(viewModel.source) { destinationType in
            switch destinationType {
            case .placeholder(let text):
                SwapTokenSelectorItemViewPlaceholder(text: text)
            case .token(_, let viewModel):
                TokenSelectorItemView(viewModel: viewModel)
                    .allowsHitTesting(false)
            }
        } header: {
            ActionButtonsSwapHeaderView(
                headerType: viewModel.sourceHeaderType,
                remove: viewModel.removeSourceTokenAction()
            )
        }
        .backgroundColor(Colors.Background.action)

        GroupedSection(viewModel.destination) { destinationType in
            switch destinationType {
            case .placeholder(let text):
                SwapTokenSelectorItemViewPlaceholder(text: text)
            case .token(_, let viewModel):
                TokenSelectorItemView(viewModel: viewModel)
                    .allowsHitTesting(false)
            }
        } header: {
            ActionButtonsSwapHeaderView(
                headerType: viewModel.destinationHeaderType,
                remove: .none
            )
        }
        .backgroundColor(Colors.Background.action)
    }

    @ViewBuilder
    private var notifications: some View {
        if let notification = viewModel.notificationInput {
            NotificationView(input: notification)
                .setButtonsLoadingState(to: viewModel.notificationIsLoading)
                .transition(.notificationTransition)
        }
    }

    private var selector: some View {
        TokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
            SwapTokenSelectorEmptyContentView(
                marketsTokensViewModel: viewModel.marketsTokensViewModel,
                message: Localization.expressTokenListEmptySearch
            )
        } headerContent: {
            header
            notifications
        } additionalContent: {
            if viewModel.shouldShowMarketsSearch, let marketsViewModel = viewModel.marketsTokensViewModel {
                SwapMarketsTokensView(viewModel: marketsViewModel)
            }
        }
        .searchType(.native)
    }
}

private struct SwapTokenSelectorItemViewPlaceholder: View {
    let text: String

    var body: some View {
        Text(text)
            .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            .multilineTextAlignment(.center)
            .padding(.vertical, 9)
            .infinityFrame(axis: .horizontal)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(style: .init(lineWidth: 1, dash: [4], dashPhase: 6))
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.vertical, 14)
    }
}
