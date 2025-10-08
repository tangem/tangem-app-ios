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
        let chartState: YieldChartContainerState
        let tokenName: String
        let tokenSymbol: String
        let transferMode: String
        let availableBalance: String
        let readMoreUrl: URL

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
                Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 4)

                LoadableTextView(
                    state: apyState,
                    font: Fonts.Bold.title2,
                    textColor: Colors.Text.accent,
                    loaderSize: .init(width: 100, height: 28)
                )
                .padding(.bottom, 8)

                Divider().overlay(Colors.Stroke.primary)
                    .padding(.bottom, 8)

                YieldModuleEarnInfoChartContainer(state: chartState)
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
            let fullString = Localization.yieldModuleEarnSheetProviderDescription(tokenName, tokenSymbol)
                + " "
                + Localization.commonReadMore

            var attr = AttributedString(fullString)
            attr.font = Fonts.Regular.caption1
            attr.foregroundColor = Colors.Text.tertiary

            if let range = attr.range(of: Localization.commonReadMore) {
                attr[range].foregroundColor = Colors.Text.accent
                attr[range].link = readMoreUrl
            }

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
