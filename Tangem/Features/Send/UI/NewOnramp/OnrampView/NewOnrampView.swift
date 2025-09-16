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
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(spacing: 12) {
            NewOnrampAmountView(viewModel: viewModel.onrampAmountViewModel)
                .padding(.top, 12)

            providersView

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

            MainButton(title: Localization.onrampAllOffersButtonTitle, style: .secondary) {
                viewModel.userDidTapAllOffersButton()
            }
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        switch viewModel.viewState {
        case .amount:
            VStack(spacing: 16) {
                Text(.init("Service is provided by an external provider.\nTangem is not responsible."))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)

                MainButton(title: Localization.commonContinue) {
                    keyboardActive = false
                    viewModel.usedDidTapContinue()
                }
            }
            .padding(.bottom, 14)
            .padding(.horizontal, 16)
            .transition(.offset(y: 500))
        case .suggestedOffers:
            EmptyView()
        }
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.legalText {
            Text(legalText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .hidden(keyboardActive)
                .animation(.default, value: keyboardActive)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerToSLink)
        }
    }
}

extension NewOnrampView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}
