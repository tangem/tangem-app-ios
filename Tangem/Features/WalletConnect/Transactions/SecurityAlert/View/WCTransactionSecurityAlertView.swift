//
//  WCTransactionSecurityAlertView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCTransactionSecurityAlertView: View {
    @StateObject private var viewModel: WCTransactionSecurityAlertViewModel

    init(state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput) {
        _viewModel = StateObject(wrappedValue: .init(state: state, input: input))
    }

    var body: some View {
        content
            .background(Colors.Background.tertiary)
            .frame(maxWidth: .infinity)
    }

    private var content: some View {
        VStack(spacing: 0) {
            WalletConnectNavigationBarView(backButtonAction: { viewModel.handleViewAction(.backButtonTapped) })

            VStack(spacing: 0) {
                icon
                    .padding(.init(top: 8, leading: 16, bottom: 24, trailing: 16))

                VStack(spacing: 8) {
                    Text(viewModel.state.title)
                        .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                        .lineLimit(2)
                        .padding(.horizontal, 16)

                    Text(LocalizedStringKey(viewModel.state.subtitle))
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .lineLimit(6)
                        .padding(.init(top: 0, leading: 16, bottom: 50, trailing: 16))

                    makeButton(from: viewModel.state.primaryButton, action: { viewModel.handleViewAction(.primaryButtonTapped) })

                    makeButton(
                        from: viewModel.state.secondaryButton,
                        icon: .trailing(Assets.tangemIcon),
                        action: { viewModel.handleViewAction(.secondaryButtonTapped) }
                    )
                }
                .multilineTextAlignment(.center)
            }
            .padding(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
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

    private func makeButton(
        from state: WCTransactionSecurityAlertState.ButtonSettings,
        icon: MainButton.Icon? = nil,
        action: @escaping () -> Void
    ) -> MainButton {
        MainButton(
            settings: .init(
                title: state.title,
                icon: icon,
                style: state.style,
                isLoading: state.isLoading,
                action: action
            )
        )
    }
}
