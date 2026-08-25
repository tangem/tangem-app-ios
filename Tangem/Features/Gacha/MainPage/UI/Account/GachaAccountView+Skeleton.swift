//
//  GachaAccountView+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension GachaAccountView {
    struct Skeleton: View {
        var body: some View {
            VStack(spacing: 0) {
                balance

                Shimmer()
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.collectionRowHeight)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: GachaAccountView.Metrics.collectionRowCornerRadius,
                            style: .continuous
                        )
                    )
                    .padding(.horizontal, GachaAccountView.Metrics.horizontalPadding)
                    .padding(.top, GachaAccountView.Metrics.collectionRowTopPadding)
            }
        }
    }
}

private extension GachaAccountView.Skeleton {
    // MARK: - View properties

    var balance: some View {
        VStack(spacing: 0) {
            bar(width: Metrics.balanceWidth, height: Metrics.balanceHeight)

            bar(width: Metrics.cryptoWidth, height: Metrics.captionHeight)
                .padding(.top, GachaAccountView.Metrics.cryptoBalanceTopPadding)

            actionButtons
                .padding(.top, GachaAccountView.Metrics.actionButtonsTopPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, GachaAccountView.Metrics.topPadding)
    }

    var actionButtons: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 2, id: \.self) { _ in
                Shimmer()
                    .frame(size: .init(bothDimensions: Metrics.actionSize))
                    .clipShape(Circle())
                    .frame(width: GachaAccountView.Metrics.actionButtonWidth)
            }
        }
    }

    func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

// MARK: - Metrics

private extension GachaAccountView.Skeleton {
    enum Metrics {
        static let balanceWidth: CGFloat = 190
        static let balanceHeight: CGFloat = 52
        static let cryptoWidth: CGFloat = 110
        static let captionHeight: CGFloat = 16
        static let actionSize: CGFloat = 56
        static let collectionRowHeight: CGFloat = 72
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaAccountView.Skeleton()
    }
}
