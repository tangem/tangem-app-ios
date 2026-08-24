//
//  MobileRemoveWalletNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileRemoveWalletNotificationView: View {
    typealias ViewModel = MobileRemoveWalletNotificationViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            content
                .padding(.top, 8)
                .padding(.horizontal, 16)

            footer
                .padding(.top, 48)
        }
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension MobileRemoveWalletNotificationView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var content: some View {
        VStack(spacing: 0) {
            warningIcon

            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, 32)

            Text(viewModel.description)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    var warningIcon: some View {
        if viewModel.isICloudBackupFeatureAvailable {
            backupWarningIcon
        } else {
            seedWarningIcon
        }
    }

    var backupWarningIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusWarningSubtle)
                .frame(width: 72, height: 72)

            DesignSystem.Icons.Warning.filled28.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }

    var seedWarningIcon: some View {
        ZStack {
            Circle()
                .fill(Colors.Text.warning.opacity(0.1))
                .frame(width: 56, height: 56)

            Assets.redCircleWarning.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.warning)
                .frame(width: 30, height: 30)
                .background {
                    Circle()
                        .fill(Colors.Text.constantWhite)
                        .padding(4)
                }
        }
    }

    var footer: some View {
        actions(
            primary: viewModel.primaryAction,
            secondary: viewModel.secondaryAction
        )
    }

    func actions(primary: ViewModel.Action, secondary: ViewModel.Action) -> some View {
        VStack(spacing: 8) {
            Button(
                label: secondary.title,
                accessibilityLabel: nil,
                action: secondary.handler
            )
            .styleType(.secondary)
            .horizontalLayout(.infinity)
            .size(.x12)

            Button(
                label: primary.title,
                accessibilityLabel: nil,
                action: primary.handler
            )
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
        }
    }
}
