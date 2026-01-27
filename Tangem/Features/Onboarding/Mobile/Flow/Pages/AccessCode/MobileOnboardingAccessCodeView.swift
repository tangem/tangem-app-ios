//
//  MobileOnboardingAccessCodeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileOnboardingAccessCodeView: View {
    typealias ViewModel = MobileOnboardingAccessCodeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .ifLet(viewModel.leadingNavBarItem) { view, item in
                view.flowNavBar(leadingItem: item.view)
            }
            .ifLet(viewModel.trailingNavBarItem) { view, item in
                view.flowNavBar(trailingItem: item.view)
            }
            .background(Color.clear.alert(item: $viewModel.alert) { $0.alert })
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .animation(.default, value: viewModel.state)
    }
}

// MARK: - Subviews

private extension MobileOnboardingAccessCodeView {
    @ViewBuilder
    var content: some View {
        VStack(spacing: 40) {
            infoView(viewModel.infoItem)

            OnboardingPinStackView(
                maxDigits: viewModel.codeLength,
                handleKeyboard: false,
                isDisabled: false,
                pinText: viewModel.code
            )
            .pinStackColor(viewModel.pinColor)
            .pinStackSecured(viewModel.isPinSecured)
            .shake(
                trigger: viewModel.shakeTrigger,
                duration: viewModel.shakeDuration,
                shakesPerUnit: 3,
                travelDistance: 10
            )
        }
        .padding(.top, 32)
    }

    func infoView(_ item: ViewModel.InfoItem) -> some View {
        VStack(spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(item.description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}
