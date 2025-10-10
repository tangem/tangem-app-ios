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
        let blockchainName: String

        var body: some View {
            VStack(spacing: 26) {
                currentFeeSection
                maximumFeeSection
            }
        }

        private var currentFeeSection: some View {
            YieldFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetCurrentFeeTitle,
                state: tokenFeeState,
                footerText: Localization.yieldModuleFeePolicySheetCurrentFeeNote(blockchainName),
                linkTitle: nil,
                url: nil,
                onLinkTapAction: {}
            )
        }

        private var maximumFeeSection: some View {
            YieldFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetMaxFeeTitle,
                state: maximumFeeState,
                footerText: Localization.yieldModuleFeePolicySheetMaxFeeNote,
                linkTitle: nil,
                url: nil,
                onLinkTapAction: {}
            )
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
