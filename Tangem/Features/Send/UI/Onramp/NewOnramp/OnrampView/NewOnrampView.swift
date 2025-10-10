//
//  NewOnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NewOnrampView: View {
    @ObservedObject var viewModel: NewOnrampViewModel
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(spacing: 12) {
            NewOnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            middleContainer

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) { bottomContainer }
        .animation(SendTransitions.animation, value: viewModel.viewState)
    }

    @ViewBuilder
    private var middleContainer: some View {
        switch viewModel.viewState {
        case .idle, .presets:
            EmptyView()

        case .loading:
            loadingView
                .transition(.opacity)

        case .suggestedOffers(let offers):
            providersView(offers: offers)
                .transition(SendTransitions.transition)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text(Localization.expressFetchBestRates)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func providersView(offers: NewOnrampViewModel.SuggestedOffers) -> some View {
        if let recent = offers.recent {
            VStack(alignment: .leading, spacing: 8) {
                DefaultHeaderView(Localization.onrampRecentlyUsedTitle)
                    .padding(.leading, 14)

                OnrampOfferView(viewModel: recent)
            }
            .padding(.top, 12)
        }

        if !offers.recommended.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                DefaultHeaderView(Localization.onrampRecommendedTitle)
                    .padding(.leading, 14)

                ForEach(offers.recommended) {
                    OnrampOfferView(viewModel: $0)
                }
            }
            .padding(.top, 12)
        }

        if offers.shouldShowAllOffersButton {
            MainButton(title: Localization.onrampAllOffersButtonTitle, style: .secondary) {
                keyboardActive = false
                viewModel.userDidTapAllOffersButton()
            }
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        switch viewModel.viewState {
        case .idle, .loading, .suggestedOffers:
            EmptyView()
        case .presets(let presets):
            HStack(spacing: 4) {
                ForEach(presets) { preset in
                    Button(action: { viewModel.usedDidTapPreset(preset: preset) }) {
                        Text(.init(preset.formatted))
                            .padding(.vertical, 6)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                            .infinityFrame(axis: .horizontal)
                            .background(Colors.Button.secondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .animation(.default, value: keyboardActive)
            .visible(keyboardActive)
        }
    }
}
