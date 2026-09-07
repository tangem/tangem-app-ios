//
//  CollectiblesAccountView+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemUI

extension CollectiblesAccountView {
    struct Skeleton: View {
        var body: some View {
            VStack(spacing: 0) {
                balance

                Shimmer()
                    .infinityFrame(axis: .horizontal)
                    .frame(height: Metrics.collectionRowHeight)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: CollectiblesAccountView.Metrics.collectionRowCornerRadius,
                            style: .continuous
                        )
                    )
                    .padding(.horizontal, CollectiblesAccountView.Metrics.horizontalPadding)
                    .padding(.top, CollectiblesAccountView.Metrics.collectionRowTopPadding)
            }
        }
    }
}

private extension CollectiblesAccountView.Skeleton {
    // MARK: - View properties

    var balance: some View {
        VStack(spacing: 0) {
            bar(width: Metrics.balanceWidth, height: Metrics.balanceHeight)

            bar(width: Metrics.cryptoWidth, height: Metrics.captionHeight)
                .padding(.top, CollectiblesAccountView.Metrics.cryptoBalanceTopPadding)

            actionButtons
                .padding(.top, CollectiblesAccountView.Metrics.actionButtonsTopPadding)
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, CollectiblesAccountView.Metrics.topPadding)
    }

    var actionButtons: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 2, id: \.self) { _ in
                Shimmer()
                    .frame(size: .init(bothDimensions: Metrics.actionSize))
                    .clipShape(Circle())
                    .frame(width: CollectiblesAccountView.Metrics.actionButtonWidth)
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

private extension CollectiblesAccountView.Skeleton {
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

        CollectiblesAccountView.Skeleton()
    }
}
