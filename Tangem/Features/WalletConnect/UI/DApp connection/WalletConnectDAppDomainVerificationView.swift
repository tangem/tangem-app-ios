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
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, viewModel.state.severity.contentBottomPadding)
        .padding(.horizontal, 32)
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
