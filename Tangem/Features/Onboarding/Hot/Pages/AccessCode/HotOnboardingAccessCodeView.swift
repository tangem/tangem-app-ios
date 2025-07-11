//
//  HotOnboardingAccessCodeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct HotOnboardingAccessCodeView: View {
    typealias ViewModel = HotOnboardingAccessCodeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .animation(.default, value: viewModel.state)
    }
}

// MARK: - Subviews

private extension HotOnboardingAccessCodeView {
    @ViewBuilder
    var content: some View {
        VStack(spacing: 40) {
            infoView(viewModel.infoItem)

            OnboardingPinStackView(
                maxDigits: viewModel.codeLength,
                isDisabled: false,
                pinText: viewModel.code
            )
            .pinStackColor(viewModel.pinColor)
            .pinStackSecured(viewModel.isPinSecured)
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
