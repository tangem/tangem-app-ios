//
//  YieldModuleEarnInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

extension YieldModuleInfoView {
    struct YieldModuleEarnInfoView: View {
        // MARK: - Properties

        let apyState: LoadableTextView.State
        let tokenName: String
        let tokenSymbol: String
        let transferMode: String
        let availableBalance: String

        // MARK: - View Body

        var body: some View {
            VStack(spacing: 8) {
                topSection
                myFundsSection
            }
        }

        // MARK: - Sub Views

        private var topSection: some View {
            VStack(alignment: .leading, spacing: .zero) {
                // Not implemented in the MVP

//                Text(Localization.yieldModuleEarnSheetTotalEarningsTitle)
//                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
//                    .padding(.top, 4)
//                    .padding(.bottom, 10)
//
//                Text(params.earningsData.totalEarnings)
//                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
//                    .padding(.bottom, 14)

                HStack {
                    Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)
                        .lineLimit(1)

                    Spacer()

                    LoadableTextView(
                        state: apyState,
                        font: Fonts.Regular.body,
                        textColor: Colors.Text.tertiary,
                        loaderSize: .init(width: 44, height: 24)
                    )
                }
                .padding(.bottom, 18)

                // [REDACTED_TODO_COMMENT]
            }
            .defaultRoundedBackground()
        }

        private var providerTitle: some View {
            HStack(spacing: 6) {
                Assets.YieldModule.yieldModuleAaveLogo.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))

                Text(Localization.yieldModuleProvider)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
            }
        }

        private var myFundsDescription: some View {
            var attr = AttributedString(Localization.yieldModuleEarnSheetProviderDescription(tokenName, tokenSymbol))
            attr.font = Fonts.Regular.caption1
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.commonReadMore)
            linkPart.font = Fonts.Regular.caption1
            linkPart.foregroundColor = Colors.Text.accent

            attr.append(AttributedString(" "))
            attr.append(linkPart)

            return Text(attr)
                .multilineTextAlignment(.leading)
        }

        private var myFundsSection: some View {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.yieldModuleEarnSheetMyFundsTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                providerTitle.padding(.bottom, 8)

                myFundsDescription.padding(.bottom, 10)

                VStack(spacing: 12) {
                    row(title: Localization.yieldModuleEarnSheetTransfersTitle, trailing: transferMode)
                    row(title: Localization.yieldModuleEarnSheetAvailableTitle, trailing: availableBalance)
                }
            }
            .defaultRoundedBackground()
        }
    }
}

private extension YieldModuleInfoView.YieldModuleEarnInfoView {
    private func row(title: String, trailing: String) -> some View {
        VStack(spacing: 14) {
            Divider().overlay(Colors.Stroke.primary)

            HStack {
                Text(title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .lineLimit(1)

                Spacer()

                Text(trailing)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }
}
