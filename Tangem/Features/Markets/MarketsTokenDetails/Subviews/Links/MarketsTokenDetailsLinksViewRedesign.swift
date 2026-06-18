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
            Text(item.section.title)
                .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
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
        var text = AttributedString(item.data.text)
        text.setFontStyle(Font.Tangem.Body16.semibold)

        let content: TangemButton.Content = {
            if let imageType = item.iconImageType {
                return .combined(
                    text: text,
                    icon: imageType,
                    iconPosition: .left
                )
            }
            return .text(text)
        }()

        return TangemButton(content: content, action: item.data.action)
            .setStyleType(.secondary)
            .setSize(.x8)
            .setCornerStyle(.rounded)
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
