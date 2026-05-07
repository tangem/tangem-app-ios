//
//  WalletConnectPayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct WalletConnectPayView: View {
    @ObservedObject var viewModel: WalletConnectPayViewModel

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(Colors.Background.tertiary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomButton
        }
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.paySheet)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .loading:
            loadingView("Preparing your payment...")
        case .options:
            optionsView
        case .dataCollection(let url):
            WalletConnectPayDataCollectionView(
                url: url,
                onComplete: { viewModel.handleDataCollectionComplete() },
                onError: { viewModel.handleDataCollectionError($0) }
            )
        case .signing:
            loadingView("Sign and send payment actions")
        case .result(let result):
            resultView(result)
        case .error(let message):
            resultView(WalletConnectPayResultState(kind: .failed, title: "Payment failed", message: message))
        }
    }

    private var navigationBar: some View {
        FloatingSheetNavigationBarView(
            backgroundColor: Colors.Background.tertiary,
            bottomSeparatorLineIsVisible: false,
            closeButtonAction: { viewModel.close() },
            titleAccessibilityIdentifier: WalletConnectAccessibilityIdentifiers.payHeaderTitle
        )
        .overlay {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
        }
    }

    private var optionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                merchantHeader
                targetSelector
                paymentOptions
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 96)
        }
    }

    private var merchantHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Payment request")
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            Text(viewModel.merchantName)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Colors.Background.action)
        .cornerRadius(16)
    }

    private var targetSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wallet")
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            ForEach(viewModel.targets) { target in
                Button {
                    viewModel.selectTarget(target.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.title)
                                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                            Text(target.userWalletName)
                                .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                        }
                        Spacer()
                        if viewModel.selectedTargetId == target.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Colors.Icon.accent)
                        }
                    }
                    .padding(12)
                    .background(Colors.Background.action)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var paymentOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment options")
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            ForEach(viewModel.options) { option in
                Button {
                    viewModel.selectOption(option.id)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.amount.display.assetSymbol)
                                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                            Text(option.amount.display.networkName ?? option.account)
                                .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(option.amount.value)
                                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                            if option.collectData != nil {
                                Text("Info required")
                                    .style(Fonts.Regular.caption1, color: Colors.Text.accent)
                            }
                        }
                        if viewModel.selectedOptionId == option.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Colors.Icon.accent)
                        }
                    }
                    .padding(12)
                    .background(Colors.Background.action)
                    .cornerRadius(12)
                }
            }
        }
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.payOptionsList)
    }

    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(message)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func resultView(_ result: WalletConnectPayResultState) -> some View {
        VStack(spacing: 12) {
            Text(result.title)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            Text(result.message)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var bottomButton: some View {
        MainButton(
            title: viewModel.primaryButtonTitle,
            style: .primary,
            isDisabled: {
                switch viewModel.step {
                case .loading, .dataCollection, .signing:
                    return true
                case .options, .result, .error:
                    return false
                }
            }(),
            action: { viewModel.handlePrimaryButtonTap() }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Colors.Background.tertiary)
    }
}
