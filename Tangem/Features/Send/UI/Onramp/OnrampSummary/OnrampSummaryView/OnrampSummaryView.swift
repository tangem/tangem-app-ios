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
        GroupedScrollView(contentType: .plain(spacing: 8)) {
            OnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            marketingBanner

            CallToActionMarketingBannersView(banners: viewModel.callToActionMarketingBanners) { action in
                keyboardActive = false
                viewModel.userDidTapCallToActionBanner(action: action)
            }

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
    private var marketingBanner: some View {
        if let standaloneMarketingBanners = viewModel.standaloneMarketingBanners {
            StandaloneMarketingBannersView(banners: standaloneMarketingBanners)
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
            Loader()

            Text(Localization.expressFetchBestRates)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func providersView(offers: OnrampSummaryViewModel.SuggestedOffers) -> some View {
        if let recent = offers.recent {
            OnrampOffersSectionView(title: Localization.onrampRecentlyUsedTitle) {
                OnrampOfferView(viewModel: recent)
            }
        }

        if !offers.recommended.isEmpty {
            OnrampOffersSectionView(title: Localization.onrampRecommendedTitle) {
                ForEach(offers.recommended) { offer in
                    OnrampOfferView(viewModel: offer)
                }
            }
        }

        OnrampAllOffersButton {
            keyboardActive = false
            viewModel.userDidTapAllOffersButton()
        }
    }

    private var bottomContainer: some View {
        OnrampFiatPresetsBar(
            presets: presets,
            onPresetTap: { viewModel.usedDidTapPreset(preset: $0) },
            onHideKeyboardTap: { keyboardActive = false }
        )
        .animation(.default, value: keyboardActive)
        .visible(keyboardActive)
    }

    private var presets: [FiatPresetService.Preset]? {
        switch viewModel.viewState {
        case .idle, .loading, .suggestedOffers:
            nil
        case .presets(let presets):
            presets
        }
    }
}

// MARK: - Subviews

private struct OnrampOffersSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }
}

private struct OnrampAllOffersButton: View {
    let action: () -> Void

    var body: some View {
        TangemUI.Button(label: Localization.onrampAllOffersButtonTitle, accessibilityLabel: nil, action: action)
            .size(.x10)
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.allOffersButton)
    }
}

private struct OnrampFiatPresetsBar: View {
    let presets: [FiatPresetService.Preset]?
    let onPresetTap: (FiatPresetService.Preset) -> Void
    let onHideKeyboardTap: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            presetButtons

            TangemUI.Button(icon: DesignSystem.Icons.KeyboardDown.regular20, accessibilityLabel: Localization.commonHide, action: onHideKeyboardTap)
                .size(.x8)
                .styleType(.secondary(.default))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var presetButtons: some View {
        if let presets {
            HStack(spacing: 4) {
                ForEach(presets) { preset in
                    TangemUI.Button(label: preset.formatted, accessibilityLabel: nil) {
                        onPresetTap(preset)
                    }
                    .size(.x8)
                    .styleType(.secondary(.default))
                    .horizontalLayout(.infinity)
                    .minimumScaleFactor(0.7)
                }
            }
        } else {
            // Use the `Spacer()` to keep the hide keyboard button in the trailing position
            Spacer()
        }
    }
}
