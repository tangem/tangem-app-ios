//
//  MobileUnlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileUnlockView: View {
    typealias ViewModel = MobileUnlockViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .onReceive(viewModel.$isAccessCodeAvailable) { isAccessCodeAvailable in
                if !isAccessCodeAvailable {
                    // [REDACTED_TODO_COMMENT]
                    UIApplication.shared.endEditing()
                }
            }
            .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - Subviews

private extension MobileUnlockView {
    var content: some View {
        VStack(spacing: 40) {
            CloseTextButton(action: viewModel.onCloseTap)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            OnboardingPinStackView(
                maxDigits: viewModel.accessCodeLength,
                handleKeyboard: false,
                isDisabled: !viewModel.isAccessCodeAvailable,
                pinText: $viewModel.accessCode
            )
            .pinStackColor(viewModel.pinColor)
            .pinStackSecured(true)

            viewModel.infoState.map {
                infoView(state: $0)
                    .padding(.horizontal, 40)
            }

            Spacer()

            viewModel.unlockItem.map {
                unlockButton(item: $0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
        .padding(.top, 32)
    }

    @ViewBuilder
    func infoView(state: ViewModel.InfoState) -> some View {
        switch state {
        case .warning(let item):
            infoWarningView(item: item)
        }
    }

    func infoWarningView(item: ViewModel.InfoWarningItem) -> some View {
        Text(item.title)
            .style(Fonts.Regular.footnote, color: Colors.Text.warning)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    func unlockButton(item: ViewModel.UnlockItem) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Colors.Button.secondary)
                .cornerRadius(14, corners: .allCorners)
        }
    }
}
