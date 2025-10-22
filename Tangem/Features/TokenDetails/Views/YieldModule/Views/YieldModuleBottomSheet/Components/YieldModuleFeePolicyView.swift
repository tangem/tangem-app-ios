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
        // It is called "Current Fee" in this view
        let tokenFeeState: LoadableTextView.State
        let maximumFeeState: LoadableTextView.State
        let minimalAmountState: LoadableTextView.State

        let blockchainName: String

        var body: some View {
            VStack(spacing: 20) {
                minimalAmountSection
                currentFeeSection

                VStack(alignment: .leading, spacing: 14) {
                    maximumFeeSection
                    serviceFeeText
                        .padding(.leading, 14)
                }
            }
        }

        private var minimalAmountSection: some View {
            YieldFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle,
                state: minimalAmountState,
                footerText: Localization.yieldModuleFeePolicySheetMinAmountNote
            )
        }

        private var currentFeeSection: some View {
            YieldFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetCurrentFeeTitle,
                state: tokenFeeState,
                footerText: Localization.yieldModuleFeePolicySheetCurrentFeeNote(blockchainName)
            )
        }

        private var maximumFeeSection: some View {
            YieldFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetMaxFeeTitle,
                state: maximumFeeState,
                footerText: Localization.yieldModuleFeePolicySheetMaxFeeNote
            )
        }

        private var serviceFeeText: some View {
            Text(Localization.yieldModuleFeePolicyTangemServiceFeeTitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .frame(alignment: .leading)
        }
    }
}

extension YieldModuleStartView {
    struct FeeModel: Identifiable {
        var id: String {
            fee
        }

        let fee: String
    }
}
