//
//  MobileBackupICloudDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileBackupICloudDetailsView: View {
    typealias ViewModel = MobileBackupICloudDetailsViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric var iconSide: CGFloat = Layout.iconSide

    var body: some View {
        content
            .padding(Layout.contentPadding)
            .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension MobileBackupICloudDetailsView {
    var content: some View {
        VStack(spacing: .zero) {
            navigation

            icon
                .padding(.top, Layout.iconTopPadding)

            description
                .padding(.top, Layout.descriptionTopPadding)

            action
                .padding(.top, Layout.actionsTopPadding)
        }
    }

    var navigation: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .redesigned()
    }

    var icon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)

            DesignSystem.Icons.Cloud.regular24.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconBrand)
        }
        .frame(size: CGSize(bothDimensions: iconSide))
    }

    var description: some View {
        let description = viewModel.description

        return VStack(spacing: Layout.descriptionSpacing) {
            Text(description.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(description.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var action: some View {
        Button(
            label: viewModel.removeActionTitle,
            accessibilityLabel: nil,
            action: viewModel.onRemoveTap
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Constants

private extension MobileBackupICloudDetailsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let iconSide: CGFloat = 80
        static let iconTopPadding: CGFloat = 64
        static let descriptionSpacing: CGFloat = 8
        static let descriptionTopPadding: CGFloat = 32
        static let actionsTopPadding: CGFloat = 64
    }
}
