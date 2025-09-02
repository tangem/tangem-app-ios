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
            VStack(spacing: .zero) {
                toolBar.padding(.bottom, 20)

                title
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                subtitle
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                groupedSection().padding(.bottom, 22)

                groupedSection()

                Spacer()

                gotItButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }

        private var toolBar: some View {
            HStack {
                CircleButton.back { backAction() }
                Spacer()
            }
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

        private var gotItButton: some View {
            Button(action: backAction) {
                Text(Localization.commonGotIt).frame(maxWidth: .infinity)
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .gray))
        }

        private func groupedSection() -> some View {
            GroupedSection(FeeModel(fee: currentFee)) { fee in
                DefaultRowView(viewModel: .init(title: fee.fee))
            } footer: {
                DefaultFooterView("This is the current supply fee on Ethereum. The live cost will be shown on the Recieve Screen.")
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
