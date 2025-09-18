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
            var attr = AttributedString(Localization.yieldModuleStopEarningSheetFeeNote)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.commonReadMore)
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent
            linkPart.link = URL(string: "")
            attr.append(AttributedString(" "))
            attr.append(linkPart)

            return Text(attr)
                .environment(\.openURL, OpenURLAction { url in
                    params.readMoreAction()
                    return .handled
                })
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
