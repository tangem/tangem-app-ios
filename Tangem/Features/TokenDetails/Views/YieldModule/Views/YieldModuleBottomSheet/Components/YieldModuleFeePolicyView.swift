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
        let networkFeeState: NetworkFeeSection.State
        let maximumFee: String
        let blockchainName: String

        var body: some View {
            VStack(spacing: 26) {
                currentFeeSection
                maximumFeeSection
            }
        }

        private var currentFeeSection: some View {
            NetworkFeeSection(
                leadingTitle: Localization.yieldModuleFeePolicySheetCurrentFeeTitle,
                state: networkFeeState,
                footerText: Localization.yieldModuleFeePolicySheetCurrentFeeNote(blockchainName),
                linkTitle: nil,
                urlString: nil,
                onLinkTapAction: nil
            )
        }

        private var maximumFeeSection: some View {
            GroupedSection(FeeModel(fee: maximumFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.yieldModuleFeePolicySheetMaxFeeTitle, detailsType: .text(fee.fee)))
            } footer: {
                DefaultFooterView(Localization.yieldModuleFeePolicySheetMaxFeeNote)
            }
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
