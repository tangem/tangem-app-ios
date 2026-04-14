//
//  MarketsTokenDetailsLinksViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsTokenDetailsLinksViewRedesign: View {
    @ScaledMetric private var verticalSpacing: CGFloat = .unit(.x6)
    @ScaledMetric private var sectionHorizontalPadding: CGFloat = .unit(.x2)
    @ScaledMetric private var titleTopPadding: CGFloat = .unit(.x6)
    @ScaledMetric private var linkListSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var linkListTopPadding: CGFloat = .unit(.x4)

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
            Separator(
                height: .minimal,
                color: .Tangem.Graphic.Neutral.quaternary,
                axis: .horizontal
            )
            .padding(.horizontal, sectionHorizontalPadding)

            Text(item.section.title)
                .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
                .padding(.horizontal, sectionHorizontalPadding)
                .padding(.top, titleTopPadding)

            HorizontalFlowLayout(
                items: item.chips.map(LinkItem.init),
                alignment: .leading,
                horizontalSpacing: linkListSpacing,
                verticalSpacing: linkListSpacing,
                itemContent: { item in
                    TangemBadge(text: item.data.text, size: .x9)
                        .icon(item.icon)
                        .iconPosition(.leading)
                        .type(.tinted)
                        .color(.gray)
                        .shape(.rounded)
                        .onTapGesture(perform: item.data.action)
                }
            )
            .padding(.top, linkListTopPadding)
        }
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

        func hash(into hasher: inout Hasher) {
            hasher.combine(data.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.data.id == rhs.data.id
        }
    }
}
