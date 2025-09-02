//
//  StartEarningView.swift
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
    struct StartEarningView: View {
        let tokenImage: Image
        let fee: String
        let buttonAction: () -> Void
        let closeAction: () -> Void
        let showFeePolicyAction: () -> Void

        // MARK: - View Body

        var body: some View {
            YieldAccountBottomSheetContainer(
                topContent: { logos },
                title: { title },
                subtitle: { subtitle },
                content: { networkFee },
                buttonLabel: { buttonLabel },
                buttonStyle: TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth),
                closeAction: { closeAction() },
                buttonAction: { buttonAction() }
            )
        }

        // MARK: - Sub Views

        private var buttonLabel: some View {
            HStack(spacing: 10) {
                Text("Start Earning")
                Assets.tangemIcon.image
            }
        }

        private var logos: some View {
            HStack(spacing: 8) {
                tokenImage
                    .resizable()
                    .frame(size: .init(bothDimensions: 48))

                Assets.YieldAccount.aaveLogo.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 48))
            }
        }

        private var title: some View {
            // YIELD [REDACTED_TODO_COMMENT]
            Text("Start Earning")
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
        }

        private var subtitle: some View {
            // YIELD [REDACTED_TODO_COMMENT]
            Text("Your USDT will be supplied to Aave and will stay instantly available.")
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
        }

        private var feePolicyText: some View {
            var attr = AttributedString("Your next deposits will be automatically supplied to Aave. ")
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString("See fee policy")
            linkPart.font = Fonts.Regular.footnote
            linkPart.foregroundColor = Colors.Text.accent

            attr.append(linkPart)

            return Text(attr)
                .onTapGesture { showFeePolicyAction() }
                .fixedSize(horizontal: false, vertical: true)
        }

        private var networkFee: some View {
            GroupedSection(FeeModel(fee: fee)) { fee in
                DefaultRowView(viewModel: .init(title: "Network fee", detailsType: .text(fee.fee)))
            } footer: {
                feePolicyText
            }
        }
    }
}
