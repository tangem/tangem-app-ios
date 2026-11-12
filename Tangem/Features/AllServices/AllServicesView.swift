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

    @ScaledMetric private var iconScale: CGFloat = 1
    @State private var headerTitleHeight: CGFloat = 0
    @State private var isTitleInBar = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Metrics.groupSpacing) {
                topContent

                ForEach(viewModel.sections) { section($0) }
            }
            .readContentOffset(inCoordinateSpace: .named(Metrics.scrollSpace)) { contentOffset in
                isTitleInBar = contentOffset.y > Metrics.headerVerticalPadding + headerTitleHeight
            }
        }
        .coordinateSpace(name: Metrics.scrollSpace)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .topNavigation(leading: .none, actions: navigationActions, close: .enabled(viewModel.close)) {
            barTitle
        }
    }
}

// MARK: - Subviews

private extension AllServicesView {
    var barTitle: some View {
        TopNavigationTitleContent(title: viewModel.title)
            .opacity(isTitleInBar ? 1 : 0)
            .accessibilityHidden(!isTitleInBar)
            .animation(Metrics.barTitleAnimation, value: isTitleInBar)
    }

    var navigationActions: TopNavigation.Actions? {
        guard viewModel.isReferralAvailable, !isTitleInBar else { return nil }

        return .one(TopNavigation.Action(
            icon: DesignSystem.Icons.Gift.regular24,
            accessibilityLabel: viewModel.referralAccessibilityLabel,
            accessibilityIdentifier: AllServicesAccessibilityIdentifiers.referralButton,
            action: viewModel.openReferral
        ))
    }

    var topContent: some View {
        VStack(spacing: .zero) {
            header

            actionButtons
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: Metrics.titleSpacing) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .readGeometry(\.size.height, bindTo: $headerTitleHeight)

            Text(viewModel.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Metrics.headerLeadingPadding)
        .padding(.trailing, Metrics.headerTrailingPadding)
        .padding(.vertical, Metrics.headerVerticalPadding)
    }

    var actionButtons: some View {
        HStack(spacing: Metrics.actionSpacing) {
            ForEach(viewModel.actions) { actionButton($0) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Metrics.actionsHorizontalPadding)
        .padding(.vertical, Metrics.actionsVerticalPadding)
    }

    func actionButton(_ action: AllServicesAction) -> some View {
        Button(action: { viewModel.select(action) }) {
            HStack(spacing: Metrics.actionContentSpacing) {
                actionIcon(action.icon)

                Text(action.title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
            .padding(.leading, Metrics.actionLeadingPadding)
            .padding(.trailing, Metrics.actionTrailingPadding)
            .padding(.vertical, Metrics.actionVerticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(ActionButtonStyle())
        .accessibilityIdentifier(AllServicesAccessibilityIdentifiers.item(action.id.rawValue))
    }

    func actionIcon(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Metrics.actionGlyphSide * clampedIconScale, height: Metrics.actionGlyphSide * clampedIconScale)
            .foregroundStyle(DesignSystem.Color.iconStatusInfo)
            .frame(width: Metrics.actionIconSide * clampedIconScale, height: Metrics.actionIconSide * clampedIconScale)
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
            .accessibilityHidden(true)
    }

    func section(_ section: AllServicesViewModel.Section) -> some View {
        VStack(spacing: .zero) {
            Text(section.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Metrics.sectionTitleHorizontalPadding)
                .padding(.vertical, Metrics.sectionTitleVerticalPadding)

            ForEach(section.items) { row(for: $0) }
        }
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
        case .illustration(let image, let style):
            // [REDACTED_TODO_COMMENT]
            Avatar(.asset(image.image.renderingMode(.template), shape: .roundedSquare))
                .foregroundStyle(style.tint)
                .background(style.background, in: RoundedRectangle(cornerRadius: Metrics.iconCornerRadius * clampedIconScale, style: .continuous))
        }
    }

    var clampedIconScale: CGFloat {
        min(max(iconScale, 1), Metrics.iconMaxScale)
    }
}

// MARK: - Illustration style

private extension AllServicesItem.IllustrationStyle {
    var background: Color {
        switch self {
        case .brand, .brandFullTint: DesignSystem.Color.bgBrand
        }
    }

    var tint: Color {
        switch self {
        case .brand: DesignSystem.Color.iconStaticDark.opacity(0.8)
        case .brandFullTint: DesignSystem.Color.iconStaticDark
        }
    }
}

// MARK: - Action button style

private struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    DesignSystem.Color.bgSecondary

                    if configuration.isPressed {
                        DesignSystem.Color.interactionPressDefault
                    }
                }
                .clipShape(Capsule())
            }
            .contentShape(Capsule())
    }
}

// MARK: - Metrics

private extension AllServicesView {
    enum Metrics {
        static let scrollSpace = "AllServicesScroll"
        static let barTitleAnimation = Animation.easeOut(duration: 0.15)
        static let groupSpacing: CGFloat = 24
        static let titleSpacing: CGFloat = 8
        static let headerLeadingPadding: CGFloat = 20
        static let headerTrailingPadding: CGFloat = 60
        static let headerVerticalPadding: CGFloat = 8
        static let actionSpacing: CGFloat = 8
        static let actionsHorizontalPadding: CGFloat = 16
        static let actionsVerticalPadding: CGFloat = 12
        static let actionContentSpacing: CGFloat = 12
        static let actionLeadingPadding: CGFloat = 8
        static let actionTrailingPadding: CGFloat = 16
        static let actionVerticalPadding: CGFloat = 8
        static let actionIconSide: CGFloat = 32
        static let actionGlyphSide: CGFloat = 20
        static let sectionTitleHorizontalPadding: CGFloat = 16
        static let sectionTitleVerticalPadding: CGFloat = 8
        static let iconCornerRadius: CGFloat = 12
        static let iconMaxScale: CGFloat = 1.5
    }
}
