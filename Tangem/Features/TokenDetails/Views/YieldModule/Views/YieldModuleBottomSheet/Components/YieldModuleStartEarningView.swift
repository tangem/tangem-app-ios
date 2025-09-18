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

extension YieldModuleStartView {
    struct YieldModuleStartEarningView: View {
        // MARK: - Properties

        let networkFee: String
        let showFeePolicyAction: () -> Void

        // MARK: - View Body

        var body: some View {
            networkFeeView
        }

        // MARK: - Sub Views

        private var feePolicyText: some View {
            var attr = AttributedString(Localization.yieldModuleStartEarningSheetNextDeposits)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.yieldModuleStartEarningSheetFeePolicy)
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent
            linkPart.link = URL(string: "")

            attr.append(AttributedString(" "))
            attr.append(linkPart)

            return Text(attr)
                .environment(\.openURL, OpenURLAction { url in
                    showFeePolicyAction()
                    return .handled
                })
        }

        private var networkFeeView: some View {
            GroupedSection(FeeModel(fee: networkFee)) { fee in
                DefaultRowView(viewModel: .init(title: Localization.commonNetworkFeeTitle, detailsType: .text(fee.fee)))
            } footer: {
                feePolicyText
            }
        }
    }
}
