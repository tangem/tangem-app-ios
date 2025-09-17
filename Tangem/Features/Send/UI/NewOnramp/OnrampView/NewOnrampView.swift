//
//  NewOnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NewOnrampView: View {
    @ObservedObject var viewModel: NewOnrampViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(spacing: 14) {
            NewOnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            if viewModel.viewState == .offers {
                OnrampProvidersCompactView(
                    viewModel: viewModel.onrampProvidersCompactViewModel
                )
                .transition(transitionService.newSummaryViewTransition())
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            bottomContainer
                .transition(.offset(y: 500).combined(with: .opacity))
        }
        .animation(.easeOut, value: viewModel.viewState)
    }

    @ViewBuilder
    private var bottomContainer: some View {
        if viewModel.viewState == .amount {
            VStack(spacing: 8) {
                legalView

                MainButton(title: Localization.commonContinue) {
                    keyboardActive = false
                    viewModel.usedDidTapContinue()
                }
            }
            .padding(.bottom, 14)
            .padding(.horizontal, 16)
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
