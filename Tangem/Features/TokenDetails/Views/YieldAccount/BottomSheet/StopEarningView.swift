//
//  StopEarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

extension YieldPromoBottomSheetView {
    struct StopEarningView: View {
        // MARK: - Properties

        let fee: String
        let readMoreAction: () -> Void

        // MARK: - View Body

        var body: some View {
            networkFee
        }

        // MARK: - Sub Views

        private var feePolicyText: some View {
            var attr = AttributedString(Localization.yieldModuleStopEarningSheetFeeNote)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.yieldModuleEarnSheetReadMore)
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent

            attr.append(" " + linkPart)

            return Text(attr)
                .onTapGesture { readMoreAction() }
                .fixedSize(horizontal: false, vertical: true)
        }

        private var networkFee: some View {
            GroupedSection(FeeModel(fee: fee)) { fee in
                DefaultRowView(viewModel: .init(
                    title: Localization.yieldModuleStartEarningSheetNetworkFeeTitle,
                    detailsType: .text(fee.fee)
                )
                )
            } footer: {
                feePolicyText
            }
        }
    }
}
