//
//  MobileBackupNotFoundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileBackupNotFoundView: View {
    @ObservedObject var viewModel: MobileBackupNotFoundViewModel

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

private extension MobileBackupNotFoundView {
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

    var warningIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusWarningSubtle)
                .frame(width: 72, height: 72)

            DesignSystem.Icons.Warning.filled28.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }

    var footer: some View {
        VStack(spacing: 8) {
            Button(
                label: viewModel.forgetActionTitle,
                accessibilityLabel: nil,
                action: viewModel.onForgetTap
            )
            .styleType(.secondary)
            .horizontalLayout(.infinity)
            .size(.x12)

            Button(
                label: viewModel.createActionTitle,
                accessibilityLabel: nil,
                action: viewModel.onCreateTap
            )
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
        }
    }
}
