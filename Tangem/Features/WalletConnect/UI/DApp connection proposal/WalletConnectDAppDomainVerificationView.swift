//
//  WalletConnectDAppDomainVerificationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectDAppDomainVerificationView: View {
    @ObservedObject var viewModel: WalletConnectDAppDomainVerificationViewModel

    var body: some View {
        VStack(spacing: .zero) {
            navigationBar
            content
            actionButtons
        }
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            backgroundColor: Color.clear,
            closeButtonAction: {
                viewModel.handle(viewEvent: .navigationCloseButtonTapped)
            }
        )
    }

    private var content: some View {
        VStack(spacing: .zero) {
            viewModel.state.iconAsset.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(viewModel.state.severity.iconColor)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(viewModel.state.severity.iconColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                }

            Spacer()
                .frame(height: 24)

            VStack(spacing: 8) {
                Text(viewModel.state.title)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(viewModel.state.body)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }

            Spacer()
                .frame(height: 16)

            if let badge = viewModel.state.badge {
                Text(badge)
                    .style(Fonts.Bold.caption1, color: viewModel.state.severity.badgeForegroundColor)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(viewModel.state.severity.badgeBackgroundColor)
                    .clipShape(.capsule)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, 20)
        .padding(.bottom, viewModel.state.severity.contentBottomPadding)
        .padding(.horizontal, 32)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.state.buttons, id: \.self) { buttonState in
                MainButton(
                    title: buttonState.title,
                    subtitle: nil,
                    icon: nil,
                    style: buttonState.style.toMainButtonStyle,
                    size: .default,
                    isLoading: buttonState.isLoading,
                    isDisabled: false,
                    handleActionWhenDisabled: false,
                    action: {
                        viewModel.handle(viewEvent: .actionButtonTapped(buttonState.role))
                    }
                )
            }
        }
        .padding(16)
    }
}

private extension WalletConnectDAppDomainVerificationViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}

private extension WalletConnectDAppDomainVerificationViewState.Severity {
    var iconColor: Color {
        switch self {
        case .verified: Colors.Icon.accent
        case .attention: Colors.Icon.attention
        case .critical: Colors.Icon.warning
        }
    }

    var badgeForegroundColor: Color {
        switch self {
        case .verified: .clear
        case .attention: Colors.Text.primary1
        case .critical: Colors.Text.warning
        }
    }

    var badgeBackgroundColor: Color {
        switch self {
        case .verified: .clear
        case .attention: Colors.Button.disabled
        case .critical: Colors.Text.warning.opacity(0.1)
        }
    }

    var contentBottomPadding: CGFloat {
        switch self {
        case .verified:
            56
        case .attention, .critical:
            24
        }
    }
}
