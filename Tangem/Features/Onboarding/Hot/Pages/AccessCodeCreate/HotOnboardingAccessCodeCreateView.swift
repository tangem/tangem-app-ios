//
//  HotOnboardingAccessCodeCreateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingAccessCodeCreateView: View {
    typealias ViewModel = HotOnboardingAccessCodeCreateViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .animation(.default, value: viewModel.state)
            // Вынести общий код в отдельное место!
            .ifLet(viewModel.leadingBavBarItem) { view, item in
                switch item {
                case .back(let action):
                    view.flowNavBar(leadingItem: { Button("back!!", action: action.closure) })
                case .skip(let action):
                    view.flowNavBar(leadingItem: { Button("skip!", action: action.closure) })
                }
            }
            .ifLet(viewModel.trailingBavBarItem) { view, item in
                switch item {
                case .back(let action):
                    view.flowNavBar(trailingItem: { Button("back!!", action: action.closure) })
                case .skip(let action):
                    view.flowNavBar(trailingItem: { Button("skip!", action: action.closure) })
                }
            }
    }
}

// MARK: - Subviews

private extension HotOnboardingAccessCodeCreateView {
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
