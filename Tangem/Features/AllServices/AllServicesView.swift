//
//  AllServicesView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct AllServicesView: View {
    @ObservedObject var viewModel: AllServicesViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Metrics.headerSpacing) {
                header

                ForEach(viewModel.actions) { row(for: $0) }
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .topNavigation(leading: .none, close: .enabled(viewModel.close))
    }
}

// MARK: - Subviews

private extension AllServicesView {
    var header: some View {
        VStack(alignment: .leading, spacing: Metrics.titleSpacing) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Metrics.headerLeadingPadding)
        .padding(.trailing, Metrics.headerTrailingPadding)
        .padding(.vertical, Metrics.headerVerticalPadding)
    }

    func row(for item: AllServicesItem) -> some View {
        Row(title: item.title, subtitle: item.subtitle)
            .start { avatar(item.icon) }
            .end { chevron }
            .onTap(action: { viewModel.select(item) })
            .accessibilityIdentifier(AllServicesAccessibilityIdentifiers.item(item.id.rawValue))
    }

    var chevron: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .flipsForRightToLeftLayoutDirection(true)
            .accessibilityHidden(true)
    }
}

// MARK: - Avatar

private extension AllServicesView {
    @ViewBuilder
    func avatar(_ icon: AllServicesItem.Icon) -> some View {
        switch icon {
        case .glyph(let image):
            Avatar(.icon(image, appearance: .info, shape: .roundedSquare))
        }
    }
}

// MARK: - Metrics

private extension AllServicesView {
    enum Metrics {
        static let headerSpacing: CGFloat = 8
        static let titleSpacing: CGFloat = 8
        static let headerLeadingPadding: CGFloat = 20
        static let headerTrailingPadding: CGFloat = 40
        static let headerVerticalPadding: CGFloat = 8
    }
}
