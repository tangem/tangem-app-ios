//
//  TangemPayCampaignSkeletonView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayCampaignSkeletonView: View {
    var body: some View {
        TangemPayCampaignLayout(
            onClose: nil,
            card: {
                TangemPayCampaignCardArtView.skeleton
            },
            texts: {
                titlePlaceholder

                bulletPlaceholder
                    .padding(.top, Constants.titleToBulletsGap)

                bulletPlaceholder
                    .padding(.top, Constants.bulletSpacing)
            },
            footer: {
                Color.clear.frame(height: Constants.reservedFooterHeight)
            }
        )
    }

    private var titlePlaceholder: some View {
        Shimmer()
            .variant(
                .custom(
                    width: Constants.titleWidth,
                    height: Constants.titleHeight,
                    cornerRadius: Constants.titleCornerRadius
                )
            )
    }

    private var bulletPlaceholder: some View {
        VStack(alignment: .leading, spacing: Constants.bulletLineSpacing) {
            shimmerLine(width: Constants.bulletTitleWidth)
            shimmerLine(width: Constants.bulletDescriptionWidth)
        }
    }

    private func shimmerLine(width: CGFloat) -> some View {
        Shimmer()
            .variant(
                .custom(
                    width: width,
                    height: Constants.bulletLineHeight,
                    cornerRadius: Constants.bulletLineCornerRadius
                )
            )
    }
}

private extension TangemPayCampaignSkeletonView {
    enum Constants {
        static let titleWidth: CGFloat = 236
        static let titleHeight: CGFloat = 28
        static let titleCornerRadius: CGFloat = 8

        static let titleToBulletsGap: CGFloat = 32
        static let bulletSpacing: CGFloat = 28
        static let bulletLineSpacing: CGFloat = 6
        static let bulletLineHeight: CGFloat = 10
        static let bulletLineCornerRadius: CGFloat = 5
        static let bulletTitleWidth: CGFloat = 134
        static let bulletDescriptionWidth: CGFloat = 76

        static let reservedFooterHeight: CGFloat = 136
    }
}
