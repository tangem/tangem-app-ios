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

extension YieldModuleBottomSheetView {
    struct YieldModuleEarnInfoView: View {
        typealias EarnInfoParams = YieldModuleBottomSheetParams.EarnInfoParams

        // MARK: - Properties

        let params: EarnInfoParams

        // MARK: - View Body

        var body: some View {
            GroupedScrollView(spacing: 8, showsIndicators: false) {
                topSection
                myFundsSection
            }
            .padding(.horizontal, -16)
        }

        // MARK: - Sub Views

        private var topSection: some View {
            GroupedSection(params.earningsData) { data in
                topSectionContent(data: data)
            }
        }

        private func topSectionContent(data: EarnInfoParams.EarningsData) -> some View {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.yieldModuleEarnSheetTotalEarningsTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                Text(data.totalEarnings)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                    .padding(.bottom, 14)

                row(title: Localization.yieldModuleEarnSheetCurrentApyTitle, trailing: params.apy)

                // [REDACTED_TODO_COMMENT]
                Rectangle()
                    .fill(.white)
                    .frame(height: 136)
            }
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
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.yieldModuleEarnSheetProviderDescription(params.tokenName, params.tokenSymbol))
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 4)

                Text(Localization.commonReadMore)
                    .style(Fonts.Regular.caption1, color: Colors.Text.accent)
                    .onTapGesture {
                        params.onReadMoreAction()
                    }
            }
        }

        private var myFundsSection: some View {
            GroupedSection(params.availableFunds) { model in
                VStack(alignment: .leading, spacing: .zero) {
                    Text(Localization.yieldModuleEarnSheetMyFundsTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    providerTitle.padding(.bottom, 8)

                    myFundsDescription.padding(.bottom, 14)

                    row(title: Localization.yieldModuleEarnSheetTransfersTitle, trailing: params.transferMode)

                    row(title: Localization.yieldModuleEarnSheetAvailableTitle, trailing: model.availableBalance)
                }
            }
        }
    }
}

private extension YieldModuleBottomSheetView.YieldModuleEarnInfoView {
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
        .padding(.bottom, 12)
    }
}
