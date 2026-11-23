//
//  AuthWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct AuthWalletView: View {
    @StateObject private var viewModel: AuthWalletViewModel

    @Environment(\.unlockingUserWalletId) private var unlockingUserWalletId: UserWalletId?

    init(item: AuthViewState.WalletItem) {
        _viewModel = StateObject(wrappedValue: AuthWalletViewModel(item: item))
    }

    var body: some View {
        SwiftUI.Button(action: viewModel.onTap) {
            HStack(spacing: 12) {
                icon
                info.frame(maxWidth: .infinity, alignment: .leading)
                loader
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadius(14, corners: .allCorners)
        }
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.walletItem(walletName: viewModel.title))
    }
}

// MARK: - Subviews

private extension AuthWalletView {
    var icon: some View {
        UserWalletIconView(icon: viewModel.icon, size: 36)
    }

    var info: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 4) {
                Text(viewModel.description)
                    .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)

                if viewModel.isProtected {
                    Assets.stakingLockIcon.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(DesignSystem.Color.iconSecondary)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }

    @ViewBuilder
    var loader: some View {
        if viewModel.isUnlocking(with: unlockingUserWalletId) {
            ProgressView()
                .controlSize(.regular)
        }
    }
}
