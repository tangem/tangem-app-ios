//
//  CollectiblesMachineView+Footer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

extension CollectiblesMachineView {
    struct Footer: View {
        let expectedValueText: String?
        let openButtonText: String

        var body: some View {
            VStack(spacing: Metrics.verticalSpacing) {
                expectedValueBlock
                    .infinityFrame(axis: .horizontal, alignment: .trailing)

                openButton
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.topPadding)
            .padding(.bottom, Metrics.bottomPadding)
            .background { background.ignoresSafeArea(edges: .bottom) }
        }
    }
}

private extension CollectiblesMachineView.Footer {
    // MARK: - View properties

    var expectedValueBlock: some View {
        VStack(alignment: .trailing, spacing: Metrics.expectedValueSpacing) {
            Text(Localization.collectiblesMachineExpectedValue)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            if let expectedValueText {
                Text(expectedValueText)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            } else {
                Shimmer()
                    .frame(width: Metrics.valueShimmerWidth, height: Metrics.valueShimmerHeight)
                    .clipShape(Capsule())
            }
        }
    }

    var openButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(label: openButtonText, accessibilityLabel: nil, action: {})
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
    }

    var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, DesignSystem.Color.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Metrics.fadeHeight)
                .alignmentGuide(.top) { $0[.bottom] }
            }
    }
}

// MARK: - Metrics

private extension CollectiblesMachineView.Footer {
    enum Metrics {
        static let verticalSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 12
        static let expectedValueSpacing: CGFloat = 2
        static let valueShimmerWidth: CGFloat = 72
        static let valueShimmerHeight: CGFloat = 20
        static let fadeHeight: CGFloat = 24
    }
}
