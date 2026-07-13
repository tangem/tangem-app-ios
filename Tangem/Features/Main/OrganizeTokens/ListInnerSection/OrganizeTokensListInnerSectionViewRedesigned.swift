//
//  OrganizeTokensListInnerSectionViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct OrganizeTokensListInnerSectionViewRedesigned: View {
    let title: String
    let identifier: AnyHashable
    let isDraggable: Bool

    @ScaledMetric private var leadingPadding: CGFloat = 16
    @ScaledMetric private var trailingPadding: CGFloat = 12
    @ScaledMetric private var topPadding: CGFloat = 16
    @ScaledMetric private var bottomPadding: CGFloat = 12

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: .Tangem.Text.Neutral.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if isDraggable {
                Assets.OrganizeTokens.groupDragAndDropIcon
                    .image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
                    .overlay(
                        OrganizeTokensDragAndDropGestureMarkView(context: .init(identifier: identifier))
                            .frame(size: Constants.dragAndDropTapZoneSize)
                    )
            }
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

// MARK: - Constants

private extension OrganizeTokensListInnerSectionViewRedesigned {
    enum Constants {
        static let dragAndDropTapZoneSize = CGSize(bothDimensions: 64.0)
    }
}
