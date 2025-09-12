//
//  NewOnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers

struct NewOnrampView: View {
    @ObservedObject var viewModel: NewOnrampViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        GroupedScrollView(spacing: 14) {
            NewOnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

            OnrampProvidersCompactView(
                viewModel: viewModel.onrampProvidersCompactViewModel
            )

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            legalView
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
