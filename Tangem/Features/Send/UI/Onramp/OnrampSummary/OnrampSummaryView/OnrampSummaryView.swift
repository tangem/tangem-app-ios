//
//  OnrampSummaryView.swift
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

struct OnrampSummaryView: View {
    @ObservedObject var viewModel: OnrampSummaryViewModel
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(contentType: .plain(spacing: 12)) {
            OnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            middleContainer

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) { bottomContainer }
        .animation(SendTransitions.animation, value: viewModel.viewState.id)
        .onChange(of: viewModel.viewState) { viewState in
            switch viewState {
            case .idle, .presets:
                break
            case .loading, .suggestedOffers:
                keyboardActive = false
            }
        }
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

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text(Localization.expressFetchBestRates)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func providersView(offers: OnrampSummaryViewModel.SuggestedOffers) -> some View {
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

        MainButton(title: Localization.onrampAllOffersButtonTitle, style: .secondary) {
            keyboardActive = false
            viewModel.userDidTapAllOffersButton()
        }
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.allOffersButton)
    }

    private var bottomContainer: some View {
        HStack(spacing: 4) {
            presets

            HideKeyboardButton(focused: $keyboardActive)
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .background(Colors.Button.secondary)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .animation(.default, value: keyboardActive)
        .visible(keyboardActive)
    }

    @ViewBuilder
    private var presets: some View {
        switch viewModel.viewState {
        case .idle, .loading, .suggestedOffers:
            // Use the `Spacer()` to keep `HideKeyboardButton` in the trailing position
            Spacer()
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
        }
    }
}
