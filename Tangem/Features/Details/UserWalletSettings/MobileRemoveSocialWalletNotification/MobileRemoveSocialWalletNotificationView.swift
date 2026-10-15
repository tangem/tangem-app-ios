//
//  MobileRemoveSocialWalletNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileRemoveSocialWalletNotificationView: View {
    typealias ViewModel = MobileRemoveSocialWalletNotificationViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var iconSide: CGFloat = Layout.iconSide
    @ScaledMetric private var titleTopPadding: CGFloat = Layout.titleTopPadding
    @ScaledMetric private var descriptionTopPadding: CGFloat = Layout.descriptionTopPadding

    var body: some View {
        VStack(spacing: .zero) {
            header

            content
                .padding(.top, Layout.contentTopPadding)
                .padding(.horizontal, Layout.contentHorizontalPadding)

            footer
                .padding(.top, Layout.footerTopPadding)
        }
        .padding(Layout.padding)
        .background(DesignSystem.Color.bgSecondary)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension MobileRemoveSocialWalletNotificationView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var content: some View {
        VStack(spacing: 0) {
            deleteIcon

            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, titleTopPadding)

            Text(viewModel.description)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, descriptionTopPadding)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var deleteIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusErrorSubtle)
                .frame(width: iconSide, height: iconSide)

            DesignSystem.Icons.TrashBin.regular28.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusError)
        }
    }

    var footer: some View {
        VStack(spacing: Layout.footerSpacing) {
            makeButton(item: viewModel.deleteActionItem)
                .styleType(.secondary(.default))

            makeButton(item: viewModel.backupActionItem)
                .styleType(.primary)
        }
    }

    func makeButton(item: ViewModel.ActionItem) -> TangemUI.Button {
        Button(
            label: item.title,
            accessibilityLabel: nil,
            action: item.handler
        )
        .horizontalLayout(.infinity)
        .size(.x12)
    }
}

// MARK: - Layout

private extension MobileRemoveSocialWalletNotificationView {
    enum Layout {
        static let padding: CGFloat = 16
        static let contentTopPadding: CGFloat = 32
        static let contentHorizontalPadding: CGFloat = 16
        static let iconSide: CGFloat = 72
        static let titleTopPadding: CGFloat = 32
        static let descriptionTopPadding: CGFloat = 8
        static let footerTopPadding: CGFloat = 48
        static let footerSpacing: CGFloat = 8
    }
}
