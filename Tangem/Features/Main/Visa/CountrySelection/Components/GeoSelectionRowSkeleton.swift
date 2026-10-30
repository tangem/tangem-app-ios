//
//  GeoSelectionRowSkeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct GeoSelectionRowSkeleton: View {
    let hasFlag: Bool

    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        HStack(spacing: Constants.spacing) {
            if hasFlag {
                Shimmer()
                    .variant(
                        .custom(
                            width: Constants.flagSide * scaleFactor,
                            height: Constants.flagSide * scaleFactor
                        )
                    )
            }

            Shimmer()
                .variant(
                    .custom(
                        width: Constants.titleWidth * scaleFactor,
                        height: Constants.titleHeight * scaleFactor,
                        cornerRadius: Constants.titleCornerRadius
                    )
                )

            Spacer(minLength: .zero)
        }
        .frame(height: Constants.height)
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

// MARK: - Constants

private extension GeoSelectionRowSkeleton {
    enum Constants {
        static let height: CGFloat = 56
        static let flagSide: CGFloat = 40
        static let titleWidth: CGFloat = 160
        static let titleHeight: CGFloat = 16
        static let titleCornerRadius: CGFloat = 4
        static let spacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: .zero) {
        ForEach(0 ..< 5, id: \.self) { _ in
            GeoSelectionRowSkeleton(hasFlag: true)
        }
    }
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
