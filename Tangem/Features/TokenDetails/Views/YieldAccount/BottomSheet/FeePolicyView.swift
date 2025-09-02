//
//  FeePolicyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

extension YieldPromoBottomSheetView {
    struct FeePolicyView: View {
        let currentFee: String
        let maximumFee: String
        let backAction: () -> Void

        var body: some View {
            YieldAccountBottomSheetContainer(
                title: { title },
                subtitle: { subtitle },
                content: { content },
                buttonLabel: { Text(Localization.commonGotIt) },
                buttonStyle: TangemButtonStyle(colorStyle: .gray, layout: .flexibleWidth),
                backAction: { backAction() },
                buttonAction: { backAction() }
            )
        }

        private var title: some View {
            // YIELD [REDACTED_TODO_COMMENT]
            Text("Fee policy").style(Fonts.Bold.title2, color: Colors.Text.primary1)
        }

        private var subtitle: some View {
            // YIELD [REDACTED_TODO_COMMENT]
            Text("All future USDT top-ups will be supplied to Aave automatically, with the transaction fee deducted.")
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
        }

        private var currentFeeSection: some View {
            GroupedSection(FeeModel(fee: currentFee)) { fee in
                DefaultRowView(viewModel: .init(title: "Current fee", detailsType: .text(fee.fee)))
            } footer: {
                DefaultFooterView("This is the current supply fee on Ethereum. The live cost will be shown on the Recieve Screen.")
            }
        }

        private var maximumFeeSection: some View {
            GroupedSection(FeeModel(fee: currentFee)) { fee in
                DefaultRowView(viewModel: .init(title: "Maximum fee", detailsType: .text(fee.fee)))
            } footer: {
                DefaultFooterView("If network fees rise above maximum fee, the transaction won’t go through until they decrease. You can change this limit later.")
            }
        }

        private var content: some View {
            VStack(spacing: 14) {
                currentFeeSection
                maximumFeeSection
            }
        }
    }
}

extension YieldPromoBottomSheetView {
    struct FeeModel: Identifiable {
        var id: String {
            fee
        }

        let fee: String
    }
}
