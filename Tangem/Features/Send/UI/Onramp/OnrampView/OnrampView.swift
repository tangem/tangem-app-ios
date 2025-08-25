//
//  OnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers

struct OnrampView: View {
    @ObservedObject var viewModel: OnrampViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView(spacing: 14) {
                OnrampAmountView(
                    viewModel: viewModel.onrampAmountViewModel,
                    namespace: .init(id: namespace.id, names: namespace.names)
                )

                OnrampProvidersCompactView(
                    viewModel: viewModel.onrampProvidersCompactViewModel
                )

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                        .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
                }
            }

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

extension OnrampView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}
