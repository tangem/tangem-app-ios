//
//  YieldModuleStopEarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

extension YieldModuleInfoView {
    struct YieldModuleStopEarningView: View {
        // MARK: - Properties

        let params: YieldModuleViewConfigs.CommonParams

        // MARK: - View Body

        var body: some View {
            networkFee
        }

        // MARK: - Sub Views

        private var feePolicyText: some View {
            var attrString = AttributedString(Localization.yieldModuleStopEarningSheetFeeNote + " " + Localization.commonReadMore)
            attrString.font = Fonts.Regular.footnote
            attrString.foregroundColor = Colors.Text.tertiary

            if let range = attrString.range(of: Localization.commonReadMore) {
                attrString[range].font = Fonts.Regular.footnote
                attrString[range].foregroundColor = Colors.Text.accent
                attrString[range].link = params.readMoreUrl
            }

            return Text(attrString)
        }

        private var networkFee: some View {
            GroupedSection(FeeModel(fee: params.networkFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.commonNetworkFeeTitle, detailsType: .text(fee.fee)))
            } footer: {
                feePolicyText
            }
        }
    }
}

extension YieldModuleInfoView {
    struct FeeModel: Identifiable {
        var id: String {
            fee
        }

        let fee: String
    }
}
