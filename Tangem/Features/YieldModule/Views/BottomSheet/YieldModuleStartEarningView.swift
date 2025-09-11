//
//  YieldModuleStartEarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

extension YieldModuleBottomSheetView {
    struct YieldModuleStartEarningView: View {
        // MARK: - Properties

        let fee: String
        let showFeePolicyAction: () -> Void

        // MARK: - View Body

        var body: some View {
            networkFee
        }

        // MARK: - Sub Views

        private var feePolicyText: some View {
            var attr = AttributedString(Localization.yieldModuleStartEarningSheetNextDeposits)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.yieldModuleStartEarningSheetFeePolicy)
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent

            attr.append(" " + linkPart)

            return Text(attr)
                .onTapGesture { showFeePolicyAction() }
                .fixedSize(horizontal: false, vertical: true)
        }

        private var networkFee: some View {
            GroupedSection(FeeModel(fee: fee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.yieldModuleStartEarning, detailsType: .text(fee.fee)))
            } footer: {
                feePolicyText
            }
        }
    }
}
