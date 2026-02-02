//
//  MarketsSkeletonItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsSkeletonItemView: View {
    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        HStack(spacing: 10) {
            IconView(url: nil, size: iconSize, forceKingfisher: true)
                .padding(.trailing, 2)

            VStack(spacing: 3) {
                tokenInfoView
            }

            priceHistoryView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .disableAnimations() // Disable animations on scroll reuse
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstBaselineCustom, spacing: 4) {
                makeSkeletonView(by: Constants.skeletonMediumWidthValue)
            }

            HStack(spacing: 6) {
                makeSkeletonView(by: Constants.skeletonSmallWidthValue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var priceHistoryView: some View {
        VStack {
            makeSkeletonView(by: Constants.skeletonMediumWidthValue)
        }
        .frame(width: 56, height: 24, alignment: .center)
    }

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

extension MarketsSkeletonItemView {
    enum Constants {
        static let skeletonMediumWidthValue: String = "---------"
        static let skeletonSmallWidthValue: String = "------"
    }
}

#Preview {
    return ScrollView(.vertical) {
        ForEach(0 ..< 10) { _ in
            MarketsSkeletonItemView()
        }
    }
}
