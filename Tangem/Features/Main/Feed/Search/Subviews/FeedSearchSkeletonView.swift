//
//  FeedSearchSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedSearchSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            Shimmer()
                .variant(.custom(width: Constants.pillWidth, height: Constants.pillHeight))

            VStack(spacing: 0) {
                ForEach(0 ..< Constants.rowCount, id: \.self) { _ in
                    TokenRow(.shimmer)
                }
            }
            .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 0, radius: Constants.cornerRadius)
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

// MARK: - Constants

private extension FeedSearchSkeletonView {
    enum Constants {
        static let rowCount = 4
        static let pillWidth: CGFloat = 122
        static let pillHeight: CGFloat = 16
        static let headerSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}
