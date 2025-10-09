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

            providersView
                .transition(SendTransitions.transition)

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            bottomContainer
        }
        .animation(.easeOut, value: viewModel.viewState)
    }

    @ViewBuilder
    private var providersView: some View {
        switch viewModel.viewState {
        case .presets, .continueButton:
            EmptyView()
        case .suggestedOffers(let offers):
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
    }

    @ViewBuilder
    private var bottomContainer: some View {
        switch viewModel.viewState {
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

        case .continueButton:
            VStack(spacing: 16) {
                if viewModel.shouldShowLegalText {
                    Text(.init(Localization.onrampLegalText))
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .transition(.opacity)
                }

                MainButton(
                    title: Localization.commonContinue,
                    isLoading: viewModel.notificationButtonIsLoading,
                    isDisabled: viewModel.continueButtonIsDisabled
                ) {
                    keyboardActive = false
                    viewModel.usedDidTapContinue()
                }
            }
            .padding(.bottom, 14)
            .padding(.horizontal, 16)
            .transition(SendTransitions.transition)

        case .suggestedOffers:
            EmptyView()
        }
    }
}
