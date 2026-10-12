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
        let expectedValueText: String
        let openButtonText: String
        @Binding var isTurboModeOn: Bool
        let onTurboModeInfoTap: () -> Void
        let onOpenTap: () -> Void

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
            SwiftUI.Button(action: onTurboModeInfoTap) {
                HStack(spacing: Metrics.turboModeLabelSpacing) {
                    Text(Localization.collectiblesMachineTurboMode)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    DesignSystem.Icons.Info.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .expandingHitArea(by: Metrics.turboModeInfoHitAreaInset)
            }
            .buttonStyle(.plain)

            Toggle("", isOn: $isTurboModeOn)
                .labelsHidden()
                .accessibilityLabel(Localization.collectiblesMachineTurboMode)
                .tint(DesignSystem.Color.bgStatusInfo)
                .fixedSize()
                .scaleEffect(Metrics.toggleScale, anchor: .leading)
                .frame(width: Metrics.toggleWidth, height: Metrics.toggleHeight, alignment: .leading)
        }
    }

    var expectedValueBlock: some View {
        VStack(alignment: .trailing, spacing: Metrics.expectedValueSpacing) {
            Text(Localization.collectiblesMachineExpectedValue)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            Text(expectedValueText)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
        }
    }

    var openButton: some View {
        TangemUI.Button(label: openButtonText, accessibilityLabel: nil, action: onOpenTap)
            .styleType(.primary)
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
        static let verticalSpacing: CGFloat = 20
        static let blocksSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let expectedValueSpacing: CGFloat = 2
        static let fadeHeight: CGFloat = 24

        static let toggleWidth: CGFloat = 41
        static let toggleHeight: CGFloat = 25

        static let turboModeSpacing: CGFloat = 2
        static let turboModeLabelSpacing: CGFloat = 2
        static let turboModeInfoHitAreaInset: CGFloat = 14
        static let toggleScale: CGFloat = 0.8
    }
}
