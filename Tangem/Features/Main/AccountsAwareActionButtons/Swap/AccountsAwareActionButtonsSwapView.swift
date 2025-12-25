//
//  AccountsAwareActionButtonsSwapView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AccountsAwareActionButtonsSwapView: View {
    @ObservedObject var viewModel: AccountsAwareActionButtonsSwapViewModel

    var body: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 16)

            notifications

            selector
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonSwap)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.destination == nil)
        .animation(.easeInOut, value: viewModel.tokenSelectorState.id)
        .animation(.easeInOut, value: viewModel.notificationInput)
        .animation(.none, value: viewModel.source.id)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CircleButton.close(action: viewModel.close)
            }
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
                AccountsAwareTokenSelectorItemView(viewModel: viewModel)
                    .allowsHitTesting(false)
            }
        } header: {
            AccountsAwareActionButtonsSwapHeaderView(
                title: Localization.swappingFromTitle,
                remove: viewModel.removeSourceTokenAction()
            )
        }
        .backgroundColor(Colors.Background.action)

        GroupedSection(viewModel.destination) { destinationType in
            switch destinationType {
            case .placeholder(let text):
                SwapTokenSelectorItemViewPlaceholder(text: text)
            case .token(_, let viewModel):
                AccountsAwareTokenSelectorItemView(viewModel: viewModel)
                    .allowsHitTesting(false)
            }
        } header: {
            AccountsAwareActionButtonsSwapHeaderView(
                title: Localization.swappingToTitle,
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
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var selector: some View {
        switch viewModel.tokenSelectorState {
        case .loading:
            loadingView
                .transition(.opacity)

            Spacer()

        case .selector:
            AccountsAwareTokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
                AccountsAwareTokenSelectorEmptyContentView(message: Localization.actionButtonsSwapEmptySearchMessage)
            }
            .searchType(.native)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text(Localization.wcCommonLoading)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
        .padding(.top, 12)
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
