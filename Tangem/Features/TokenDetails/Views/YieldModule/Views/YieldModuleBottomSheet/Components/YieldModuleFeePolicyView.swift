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
        let currentFee: String
        let maximumFee: String
        let blockchainName: String

        var body: some View {
            VStack(spacing: 26) {
                currentFeeSection
                maximumFeeSection
            }
        }

        private var currentFeeSection: some View {
            GroupedSection(FeeModel(fee: currentFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.commonNetworkFeeTitle, detailsType: .text(fee.fee)))
            } footer: {
                DefaultFooterView(Localization.yieldModuleFeePolicySheetCurrentFeeNote(blockchainName))
            }
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
