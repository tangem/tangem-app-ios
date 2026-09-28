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

        @State private var isTurboModeOn = false

        @ScaledMetric private var labelShimmerHeight: CGFloat = 12
        @ScaledMetric private var valueShimmerHeight: CGFloat = 20

        var body: some View {
            VStack(spacing: Metrics.verticalSpacing) {
                HStack(alignment: .bottom, spacing: Metrics.blocksSpacing) {
                    turboModeBlock

                    expectedValueBlock
                        .infinityFrame(axis: .horizontal, alignment: .trailing)
                }

                openButton
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.topPadding)
            .background { background.ignoresSafeArea(edges: .bottom) }
        }
    }
}

private extension CollectiblesMachineView.Footer {
    // MARK: - View properties

    var turboModeBlock: some View {
        VStack(alignment: .leading, spacing: Metrics.turboModeSpacing) {
            HStack(spacing: Metrics.turboModeLabelSpacing) {
                // [REDACTED_TODO_COMMENT]
                Text(Localization.collectiblesMachineTurboMode)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }

            Toggle("", isOn: $isTurboModeOn)
                .labelsHidden()
                .accessibilityLabel(Localization.collectiblesMachineTurboMode)
                .tint(DesignSystem.Color.bgBrand)
                .fixedSize()
                .scaleEffect(Metrics.toggleScale, anchor: .leading)
                .frame(width: Metrics.toggleWidth, height: Metrics.toggleHeight, alignment: .leading)
        }
    }

    @ViewBuilder
    var expectedValueBlock: some View {
        if let expectedValueText {
            VStack(alignment: .trailing, spacing: Metrics.expectedValueSpacing) {
                Text(Localization.collectiblesMachineExpectedValue)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                Text(expectedValueText)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            }
        } else {
            VStack(alignment: .trailing, spacing: Metrics.expectedValueSpacing) {
                shimmerBar(width: Metrics.labelShimmerWidth, height: labelShimmerHeight)
                    .frame(height: Metrics.labelLineHeight)

                shimmerBar(width: Metrics.valueShimmerWidth, height: valueShimmerHeight)
                    .frame(height: Metrics.valueLineHeight)
            }
        }
    }

    func shimmerBar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }

    var openButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(label: openButtonText, accessibilityLabel: nil, action: {})
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .disabled(expectedValueText == nil)
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
        static let verticalSpacing: CGFloat = 20
        static let blocksSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let expectedValueSpacing: CGFloat = 2
        static let fadeHeight: CGFloat = 24
        static let labelShimmerWidth: CGFloat = 81
        static let labelLineHeight: CGFloat = 16
        static let valueShimmerWidth: CGFloat = 133
        static let valueLineHeight: CGFloat = 24

        static let toggleWidth: CGFloat = 41
        static let toggleHeight: CGFloat = 25

        static let turboModeSpacing: CGFloat = 2
        static let turboModeLabelSpacing: CGFloat = 2
        static let toggleScale: CGFloat = 0.8
    }
}
