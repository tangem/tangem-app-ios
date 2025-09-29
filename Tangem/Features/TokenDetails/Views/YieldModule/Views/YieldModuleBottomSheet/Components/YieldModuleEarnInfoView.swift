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
        typealias EarnInfoParams = YieldModuleViewConfigs.EarnInfoParams

        // MARK: - Properties

        let params: EarnInfoParams

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
                Text(Localization.yieldModuleEarnSheetTotalEarningsTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                Text(params.earningsData.totalEarnings)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                    .padding(.bottom, 14)

                row(title: Localization.yieldModuleEarnSheetCurrentApyTitle, trailing: params.apy)
                    .padding(.bottom, 18)

                // [REDACTED_TODO_COMMENT]
                Rectangle()
                    .fill(.white)
                    .frame(height: 120)
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
            var attr = AttributedString(
                Localization.yieldModuleEarnSheetProviderDescription(
                    params.tokenName,
                    params.tokenSymbol
                )
            )
            attr.font = Fonts.Regular.caption1
            attr.foregroundColor = Colors.Text.tertiary

            var linkPart = AttributedString(Localization.commonReadMore)
            linkPart.font = Fonts.Regular.caption1
            linkPart.foregroundColor = Colors.Text.accent
            linkPart.link = params.readMoreUrl

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
                    row(title: Localization.yieldModuleEarnSheetTransfersTitle, trailing: params.transferMode)
                    row(title: Localization.yieldModuleEarnSheetAvailableTitle, trailing: params.availableFunds.availableBalance)
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
