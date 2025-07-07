//
//  HotAccessCodeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct HotAccessCodeView: View {
    typealias ViewModel = HotAccessCodeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
    }
}

// MARK: - Subviews

private extension HotAccessCodeView {
    @ViewBuilder
    var content: some View {
        VStack(spacing: 40) {
            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            OnboardingPinStackView(
                maxDigits: viewModel.accessCodeLength,
                isDisabled: !viewModel.isAccessCodeAvailable,
                pinText: $viewModel.accessCode
            )
            .pinStackColor(viewModel.pinColor)
            .pinStackSecured(true)

            viewModel.infoState.map {
                infoView(state: $0)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.top, 32)
    }

    @ViewBuilder
    func infoView(state: ViewModel.InfoState) -> some View {
        switch state {
        case .warning(let item):
            InfoWarningView(item: item)
        }
    }

    func InfoWarningView(item: ViewModel.InfoWarningItem) -> some View {
        Text(item.title)
            .style(Fonts.Regular.footnote, color: Colors.Text.warning)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
