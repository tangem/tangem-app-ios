//
//  CollectiblesRegionRestrictionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesRegionRestrictionsView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            content

            footer
        }
    }
}

// MARK: - Content

private extension CollectiblesRegionRestrictionsView {
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
        DesignSystem.Icons.Warning.regular28.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: Metrics.iconSize))
            .foregroundStyle(DesignSystem.Color.iconStatusWarning)
            .frame(size: CGSize(bothDimensions: Metrics.avatarSize))
            .background(DesignSystem.Color.bgStatusWarningSubtle)
            .clipShape(Circle())
    }

    var texts: some View {
        VStack(spacing: Metrics.textsSpacing) {
            // [REDACTED_TODO_COMMENT]
            Text("Region restrictions")
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            // [REDACTED_TODO_COMMENT]
            Text("Tangem Packs are not supported in your region, you can still view events")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: Metrics.textsMaxWidth)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    var footer: some View {
        TangemUI.Button(label: Localization.commonClose, accessibilityLabel: nil, action: onClose)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.footerVerticalPadding)
    }
}

// MARK: - Metrics

extension CollectiblesRegionRestrictionsView {
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

// MARK: - Previews

#Preview {
    CollectiblesRegionRestrictionsView(onClose: {})
}
