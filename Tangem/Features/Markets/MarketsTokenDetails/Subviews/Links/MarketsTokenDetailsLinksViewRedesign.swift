//
//  MarketsTokenDetailsLinksViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsLinksViewRedesign: View {
    @ScaledMetric private var verticalSpacing: CGFloat = 24
    @ScaledMetric private var sectionHorizontalPadding: CGFloat = 8
    @ScaledMetric private var titleTopPadding: CGFloat = 24
    @ScaledMetric private var linkListSpacing: CGFloat = 8
    @ScaledMetric private var linkListTopPadding: CGFloat = 16

    let sections: [MarketsTokenDetailsLinkSection]

    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(sections) { item in
                sectionView(item)
            }
        }
    }
}

// MARK: - Subviews

private extension MarketsTokenDetailsLinksViewRedesign {
    func sectionView(_ item: MarketsTokenDetailsLinkSection) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(item.section.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.horizontal, sectionHorizontalPadding)
                .padding(.top, titleTopPadding)

            HorizontalFlowLayout(
                items: item.chips.map(LinkItem.init),
                alignment: .leading,
                horizontalSpacing: linkListSpacing,
                verticalSpacing: linkListSpacing,
                itemContent: { item in
                    linkButton(for: item)
                }
            )
            .padding(.top, linkListTopPadding)
        }
    }

    func linkButton(for item: LinkItem) -> some View {
        TangemUI.Button(
            label: AttributedString(item.data.text),
            accessibilityLabel: item.data.text,
            action: item.data.action
        )
        .iconStart(item.iconImageType)
        .size(.x8)
        .styleType(.secondary)
    }
}

// MARK: - Types

private extension MarketsTokenDetailsLinksViewRedesign {
    struct LinkItem: Hashable {
        let data: MarketsTokenDetailsLinkChipsData

        var icon: Image? {
            switch data.icon {
            case .leading(let imageType): imageType.image
            case .trailing(let imageType): imageType.image
            case .none: nil
            }
        }

        var iconImageType: ImageType? {
            switch data.icon {
            case .leading(let imageType), .trailing(let imageType): imageType
            case .none: nil
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(data.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.data.id == rhs.data.id
        }
    }
}
