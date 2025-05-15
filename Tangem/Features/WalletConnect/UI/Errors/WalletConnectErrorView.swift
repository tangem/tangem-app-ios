//
//  WalletConnectErrorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectErrorView: View {
    @ObservedObject var viewModel: WalletConnectErrorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            navigationBar
            content
            button
        }
        .background(Colors.Background.tertiary)
        .frame(maxWidth: .infinity)
        .onOpenURL { url in
            viewModel.handle(viewEvent: .linkTapped(url))
        }
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            closeButtonAction: { viewModel.handle(viewEvent: .closeButtonTapped) }
        )
    }

    private var content: some View {
        VStack(spacing: 24) {
            icon

            VStack(spacing: 8) {
                Text(viewModel.state.title)
                    .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                    .lineLimit(2)

                Text(LocalizedStringKey(viewModel.state.subtitle))
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .lineLimit(6)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.horizontal, 32)
        .padding(.bottom, 44)
    }

    private var icon: some View {
        viewModel.state.icon.asset.image
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundStyle(viewModel.state.icon.color)
            .frame(width: 56, height: 56)
            .background {
                Circle()
                    .fill(viewModel.state.icon.color.opacity(0.1))
            }
    }

    private var button: some View {
        MainButton(
            title: viewModel.state.button.title,
            style: viewModel.state.button.style.toMainButtonStyle,
            size: .default,
            action: { viewModel.handle(viewEvent: .buttonTapped) }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private extension WalletConnectErrorViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}
