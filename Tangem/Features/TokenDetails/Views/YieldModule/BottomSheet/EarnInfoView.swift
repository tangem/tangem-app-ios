//
//  EarnInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

extension YieldModuleBottomSheetView {
    struct EarnInfoView: View {
        let status: String
        let chartData: YieldModuleChartData
        let availableFunds: AvailableFundsData
        let transferMode: String
        let tokenName: String

        // MARK: - View Body

        var body: some View {
            GroupedScrollView(spacing: 8, showsIndicators: false) {
                chartSection
                myFundsSection
            }
            .padding(.horizontal, -16)
        }

        // MARK: - Sub Views

        private var chartSection: some View {
            GroupedSection(chartData) {
                YieldModuleChartView(model: $0)
                    .frame(height: 345)
                    .frame(maxWidth: .infinity)
            }
        }

        private var providerTitle: some View {
            HStack(spacing: 6) {
                Assets.YieldModule.aaveLogo.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))

                Text(Localization.yieldModuleProvider)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
            }
        }

        private var myFundsDescription: some View {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.yieldModuleEarnSheetProviderDescription(tokenName, tokenName))
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.leading)

                Text(Localization.commonReadMore)
                    .style(Fonts.Regular.caption1, color: Colors.Text.accent)
            }
        }

        private var myFundsSection: some View {
            GroupedSection(availableFunds) { model in
                VStack(alignment: .leading, spacing: .zero) {
                    Text(Localization.yieldModuleEarnSheetMyFundsTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    providerTitle.padding(.bottom, 6)

                    myFundsDescription.padding(.bottom, 12)

                    row(title: Localization.yieldModuleEarnSheetTransfersTitle, trailing: transferMode)

                    row(title: Localization.yieldModuleEarnSheetAvailableTitle, trailing: model.availableBalance)
                }
            }
        }
    }
}

private extension YieldModuleBottomSheetView.EarnInfoView {
    private func row(title: String, trailing: String,) -> some View {
        VStack(spacing: 10) {
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
        .padding(.bottom, 12)
    }
}

extension YieldModuleBottomSheetView.EarnInfoView {
    struct AvailableFundsData: Identifiable {
        let availableBalance: String

        var id: String {
            availableBalance
        }
    }
}
