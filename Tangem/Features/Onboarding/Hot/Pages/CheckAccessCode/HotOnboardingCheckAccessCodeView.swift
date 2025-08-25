//
//  HotOnboardingCheckAccessCodeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct HotOnboardingCheckAccessCodeView: View {
    typealias ViewModel = HotOnboardingCheckAccessCodeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
    }
}

// MARK: - Subviews

private extension HotOnboardingCheckAccessCodeView {
    @ViewBuilder
    var content: some View {
        VStack(spacing: 40) {
            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            OnboardingPinStackView(
                maxDigits: viewModel.codeLength,
                isDisabled: false,
                pinText: $viewModel.accessCode
            )
            .pinStackColor(viewModel.pinColor)
            .pinStackSecured(true)
        }
        .padding(.top, 32)
    }
}
