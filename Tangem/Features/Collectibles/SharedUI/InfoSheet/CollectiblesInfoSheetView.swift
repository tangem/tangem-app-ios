//
//  CollectiblesInfoSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesInfoSheetView: View {
    let model: Model
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            content

            footer
        }
    }
}

// MARK: - Model

extension CollectiblesInfoSheetView {
    struct Model {
        let icon: ImageType
        let iconColor: Color
        let iconBackgroundColor: Color
        let title: String
        let message: String
        let buttonTitle: String
    }
}

// MARK: - Content

private extension CollectiblesInfoSheetView {
    // MARK: - View properties

    var header: some View {
        NavigationBarButton.close(action: onClose)
            .infinityFrame(axis: .horizontal, alignment: .trailing)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.headerTopPadding)
            .padding(.bottom, Metrics.headerBottomPadding)
    }

    var content: some View {
        VStack(spacing: Metrics.avatarToTextSpacing) {
            avatar

            texts
        }
        .padding(.top, Metrics.contentTopPadding)
        .padding(.bottom, Metrics.contentBottomPadding)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    var avatar: some View {
        model.icon.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: Metrics.iconSize))
            .foregroundStyle(model.iconColor)
            .frame(size: CGSize(bothDimensions: Metrics.avatarSize))
            .background(model.iconBackgroundColor)
            .clipShape(Circle())
    }

    var texts: some View {
        VStack(spacing: Metrics.textsSpacing) {
            Text(model.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(model.message)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: Metrics.textsMaxWidth)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    var footer: some View {
        TangemUI.Button(label: model.buttonTitle, accessibilityLabel: nil, action: onClose)
            .styleType(.primary)
            .horizontalLayout(.infinity)
            .size(.x12)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.footerVerticalPadding)
    }
}

// MARK: - Metrics

extension CollectiblesInfoSheetView {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let headerTopPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 16

        static let avatarSize: CGFloat = 72
        static let iconSize: CGFloat = 28
        static let avatarToTextSpacing: CGFloat = 32
        static let textsSpacing: CGFloat = 8
        static let textsMaxWidth: CGFloat = 310

        static let contentTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 48

        static let footerVerticalPadding: CGFloat = 8

        static let estimatedHeight: CGFloat = 380
    }
}
