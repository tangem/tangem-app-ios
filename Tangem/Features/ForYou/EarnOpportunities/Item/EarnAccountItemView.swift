//
//  EarnAccountItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnAccountItemView: View {
    let item: EarnAccountListItem
    let onAccountTap: (String) -> Void

    @Namespace private var namespace

    @ScaledMetric private var chevronSize: CGFloat = 20

    private var effects: GeometryEffects {
        GeometryEffects(namespace: namespace)
    }

    var body: some View {
        card.transition(.opacity)
    }
}

private extension EarnAccountItemView {
    @ViewBuilder
    var card: some View {
        if item.isExpandable {
            expandableCard
        } else {
            staticCard
        }
    }

    var expandableCard: some View {
        ExpandableItemView(
            isExpanded: item.isExpanded,
            backgroundColor: DesignSystem.Color.bgSecondary,
            cornerRadius: 24,
            backgroundGeometryEffect: effects.background,
            expandedViewTransition: .earnExpandedContentTransition,
            collapsedView: { collapsedHeader },
            expandedView: { tokensView },
            expandedViewHeader: { expandedHeader },
            onExpandedChange: { _ in onAccountTap(item.id) }
        )
    }

    var staticCard: some View {
        collapsedHeader
            .portfolioTokenCard()
    }

    // MARK: - Collapsed

    var collapsedHeader: some View {
        TangemRow(
            subtitle: item.account.tokensCountText,
            value: item.account.rewardText
        )
        // Name goes through a slot, not the `title` string, so it keeps its matched-geometry morph.
        .titleAccessory { name(font: DesignSystem.Font.bodyMediumToken) }
        .start { icon(settings: .redesignDefaultSized) }
        .includeInnerPadding(false)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Expanded

    var expandedHeader: some View {
        VStack(spacing: 0) {
            expandedHeaderRow
            divider
        }
    }

    var expandedHeaderRow: some View {
        HStack(spacing: 12) {
            icon(settings: .smallSized)

            name(font: DesignSystem.Font.subheadingMediumToken)

            Spacer(minLength: 8)

            chevron
        }
        .padding(16)
    }

    // MARK: - Shared pieces

    func icon(settings: AccountIconView.Settings) -> some View {
        AccountIconView(
            data: .composite(
                backgroundColor: item.account.iconColor,
                nameMode: .imageType(item.account.glyph)
            ),
            settings: settings,
            iconGeometryEffect: effects.icon,
            backgroundGeometryEffect: effects.iconBackground
        )
    }

    func name(font: TangemTypographyToken) -> some View {
        Text(item.account.name)
            .style(font, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .matchedGeometryEffect(effects.name)
    }

    var chevron: some View {
        DesignSystem.Icons.ChevronCollapse.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: chevronSize, height: chevronSize)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }

    var divider: some View {
        Separator(color: DesignSystem.Color.borderSecondary)
            .padding(.horizontal, 16)
    }

    var tokensView: some View {
        VStack(spacing: 0) {
            ForEach(item.tokens) { token in
                TokenRowView(data: token)
                    .transition(.opacity)
            }
        }
    }
}

private extension AnyTransition {
    static let earnExpandedContentTransition: AnyTransition = .asymmetric(
        insertion: .offset(y: 20).combined(with: .opacity),
        removal: .opacity
    )
}
