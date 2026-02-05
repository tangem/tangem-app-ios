//
//  YieldModuleFeePolicyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

extension YieldModuleStartView {
    struct YieldModuleFeePolicyView: View {
        let minimalAmountState: YieldFeeSectionState
        let estimatedFeeState: YieldFeeSectionState
        let maximumFeeState: YieldFeeSectionState
        let footerText: String?

        var body: some View {
            VStack(spacing: 20) {
                minimalAmountSection

                VStack(alignment: .leading, spacing: 14) {
                    bottomSection
                    serviceFeeText
                        .padding(.leading, 14)
                }
            }
        }

        private var minimalAmountSection: some View {
            YieldFeeSection(sectionState: minimalAmountState, leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle)
        }

        private var bottomSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 12) {
                    YieldFeeSection(
                        sectionState: estimatedFeeState,
                        leadingTitle: Localization.commonEstimatedFee,
                        needsBackground: false
                    )

                    Separator(color: Colors.Stroke.primary)
                        .padding(.horizontal, 4)

                    YieldFeeSection(
                        sectionState: maximumFeeState,
                        leadingTitle: Localization.yieldModuleFeePolicySheetMaxFeeTitle,
                        needsBackground: false
                    )
                }
                .defaultRoundedBackground(with: Colors.Background.action)

                if let footerText {
                    Text(footerText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .padding(.horizontal, 14)
                }
            }
        }

        private var serviceFeeText: some View {
            Text(Localization.yieldModuleFeePolicyTangemServiceFeeTitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }
}
