//
//  NewOnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NewOnrampView: View {
    @ObservedObject var viewModel: NewOnrampViewModel
    let transitionService: SendTransitionService
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(spacing: 12) {
            NewOnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            providersView
                .transition(transitionService.defaultTransition)

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
        case .amount:
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
        case .amount:
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
            .transition(transitionService.defaultTransition)
        case .suggestedOffers:
            EmptyView()
        }
    }
}

extension NewOnrampView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}
