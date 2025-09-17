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

extension YieldModuleBottomSheetView {
    struct YieldModuleStopEarningView: View {
        // MARK: - Properties

        let params: YieldModuleParams.СommonParams

        // MARK: - View Body

        var body: some View {
            networkFee
        }

        // MARK: - Sub Views

        private var feePolicyText: some View {
            var attr = AttributedString(Localization.yieldModuleStopEarningSheetFeeNote)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.commonReadMore)
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent

            attr.append(" " + linkPart)

            return Text(attr)
                .onTapGesture { params.readMoreAction() }
                .fixedSize(horizontal: false, vertical: true)
        }

        private var networkFee: some View {
            GroupedSection(FeeModel(fee: params.networkFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.networkFee, detailsType: .text(fee.fee)))
            } footer: {
                feePolicyText
            }
        }
    }
}
