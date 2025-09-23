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
    @FocusState.Binding var keyboardActive: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView(spacing: 14) {
                OnrampAmountView(viewModel: viewModel.onrampAmountViewModel)

                OnrampProvidersCompactView(viewModel: viewModel.onrampProvidersCompactViewModel)

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
