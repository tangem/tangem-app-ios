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

extension YieldModuleBottomSheetView {
    struct YieldModuleFeePolicyView: View {
        let networkFee: String
        let maximumFee: String
        let blockchainName: String

        var body: some View {
            VStack(spacing: 14) {
                currentFeeSection
                maximumFeeSection
            }
        }

        private var currentFeeSection: some View {
            GroupedSection(FeeModel(fee: networkFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.yieldModuleFeePolicySheetCurrentFeeTitle, detailsType: .text(fee.fee)))
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

extension YieldModuleBottomSheetView {
    struct FeeModel: Identifiable {
        var id: String {
            fee
        }

        let fee: String
    }
}
