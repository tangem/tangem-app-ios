//
//  LendingPositionContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

// [REDACTED_TODO_COMMENT]
struct LendingPositionContentView: View {
    let state: StateModel
    let calculator: EarnCalculatorViewModel
    let action: (Action) -> Void

    @State private var isTabsPinned = false
    @State private var presentedInfo: EarnProductDetails.InfoSheet?
    @State private var presentedInfoTitle = ""
    @State private var isCalculatorPresented = false

    @ScaledMetric private var infoIconSide: CGFloat = 20

    var body: some View {
        AnchoredSectionsScrollView(
            sections: LendingPositionSection.allCases,
            isTabsPinned: $isTabsPinned,
            header: { _ in header }
        ) {
            VStack(spacing: Constants.sectionSpacing) {
                myFunds
                    .anchoredSection(LendingPositionSection.myFunds)

                EarnProductBenefitsView(benefits: state.details.benefits)
                    .anchoredSection(LendingPositionSection.benefits)

                EarnProductDetailsView(
                    details: state.details,
                    onLinkTap: { action(.openURL($0)) },
                    onInfoTap: present
                )
                .anchoredSection(LendingPositionSection.details)
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .footer {
            Footer(.buttons(primary: addFundsButton, secondary: withdrawButton, orientation: .horizontal)).showFade()
        }
        .topNavigation(
            title: "Lending on Aave",
            subtitle: "Ethereum in Mainnet",
            leading: .automatic,
            close: .enabled { action(.close) }
        )
        .modal(
            item: $presentedInfo,
            contentLayout: .intrinsic,
            navigation: .title(presentedInfoTitle)
        ) { info in
            EarnProductInfoSheetView(sheet: info)
        }
        .modal(
            isPresented: $isCalculatorPresented,
            contentLayout: .intrinsic,
            navigation: .title("Calculate your earnings")
        ) {
            EarnCalculatorView(viewModel: calculator, onIncentiveInfoTap: {}, showsCard: false)
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    func present(_ info: EarnProductDetails.InfoSheet) {
        presentedInfoTitle = info.title
        presentedInfo = info
    }
}

// MARK: - Header

private extension LendingPositionContentView {
    var header: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            balance
            periodRow
            apy
        }
        .padding(.top, Constants.headerTopPadding)
    }

    var balance: some View {
        VStack(spacing: Constants.balanceSpacing) {
            Text(state.balance?.fiat ?? Constants.placeholder)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Constants.amountMinScale)
                .shimmerPlaceholder(state.balance == nil)

            Text(state.balance?.crypto ?? Constants.placeholder)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .shimmerPlaceholder(state.balance == nil)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    var periodRow: some View {
        HStack(spacing: Constants.periodSpacing) {
            SegmentedControl(
                items: LendingApyHistoryPeriod.allCases.map { SegmentedControl.Item(id: $0, title: $0.title) },
                selection: Binding(
                    get: { state.period },
                    set: { action(.selectPeriod($0)) }
                )
            )

            TangemUI.Button(
                icon: DesignSystem.Icons.Calculator.regular20,
                accessibilityLabel: "Calculate your earnings",
                action: { isCalculatorPresented = true }
            )
            .styleType(.secondary(.default))
            .size(.x9)
            .enabled(state.isApyKnown)
        }
        .padding(.horizontal, Constants.controlsHorizontalPadding)
    }

    var apy: some View {
        VStack(alignment: .leading, spacing: Constants.apySpacing) {
            VStack(alignment: .leading, spacing: Constants.balanceSpacing) {
                Text("Current APY")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                UtilPriceChange(value: state.currentApy, direction: state.isApyKnown ? .positive : .neutral)
                    .typography(DesignSystem.Font.headingMediumToken)
            }
            .accessibilityElement(children: .combine)

            chart
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    var chart: some View {
        switch state.chart {
        case .loading:
            LendingApyChart(state: .loading)
        case .loaded(let data):
            LendingApyChart(state: .loaded(apyData: data.buckets, xAxisTicks: data.xTicks, averageApy: data.averageApy))
        case .error(let retry):
            VStack(spacing: Constants.errorSpacing) {
                Text(Localization.yieldModuleChartLoadingError)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)

                TangemUI.Button(label: Localization.alertButtonTryAgain, accessibilityLabel: nil) {
                    Task { await retry() }
                }
                .styleType(.secondary(.default))
                .size(.x9)
            }
            .frame(maxWidth: .infinity, minHeight: Constants.chartHeight)
        }
    }
}

// MARK: - My Funds

private extension LendingPositionContentView {
    var myFunds: some View {
        VStack(alignment: .leading, spacing: 0) {
            EarnProductSectionTitle(title: "My Funds")

            Row(title: "Aave", value: "How it works")
                .start {
                    Avatar(.asset(Assets.YieldModule.yieldModuleAaveLogo.image), size: .size40)
                }
                .valueAccessory {
                    DesignSystem.Icons.ChevronRight.regular20.image
                        .renderingMode(.template)
                        .flipsForRightToLeftLayoutDirection(true)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                        .accessibilityHidden(true)
                }
                .showDivider(false)
                .onTap { action(.howItWorks) }
                .padding(.horizontal, Constants.rowsHorizontalPadding)

            Text("Your ETH is supplied to Aave and is earning interest. Your balance grows automatically, with no action needed. Withdraw anytime, subject to available Aave liquidity. New ETH you receive stays in your wallet, and you can supply more whenever you like")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.paragraphVerticalPadding)

            VStack(spacing: 0) {
                fundsRow(info: state.totalBalanceInfo, value: state.balance?.crypto)
                fundsRow(info: state.availableBalanceInfo, value: state.availableBalance)
            }
            .padding(.horizontal, Constants.rowsHorizontalPadding)
        }
    }

    func fundsRow(info: EarnProductDetails.InfoSheet, value: String?) -> some View {
        Row(title: info.title, value: value ?? Constants.placeholder)
            .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
            .showDivider()
            .onTap { present(info) }
            .titleAccessory {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: infoIconSide, height: infoIconSide)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .accessibilityHidden(true)
            }
            .shimmerPlaceholder(value == nil)
    }
}

// MARK: - Footer

private extension LendingPositionContentView {
    var withdrawButton: TangemUI.Button {
        TangemUI.Button(label: "Withdraw", accessibilityLabel: nil) { action(.withdraw) }
            .styleType(.secondary(.default))
            .enabled(state.canWithdraw && !state.isAddFundsLoading)
            .loading(.spinner(if: state.isWithdrawLoading))
    }

    var addFundsButton: TangemUI.Button {
        TangemUI.Button(label: Localization.commonAddFunds, accessibilityLabel: nil) { action(.addFunds) }
            .styleType(.primary)
            .enabled(!state.isWithdrawLoading)
            .loading(.spinner(if: state.isAddFundsLoading))
    }
}

// MARK: - State Model

extension LendingPositionContentView {
    struct StateModel {
        var balance: Balance?
        var availableBalance: String?
        let currentApy: String
        let isApyKnown: Bool
        var chart: YieldChartContainerState
        var period: LendingApyHistoryPeriod
        var canWithdraw: Bool
        var isAddFundsLoading = false
        var isWithdrawLoading = false

        var isRouteLoading: Bool {
            isAddFundsLoading || isWithdrawLoading
        }

        let details: EarnProductDetails
        let totalBalanceInfo: EarnProductDetails.InfoSheet
        let availableBalanceInfo: EarnProductDetails.InfoSheet

        struct Balance: Equatable {
            let fiat: String
            let crypto: String
        }
    }

    enum Action {
        case selectPeriod(LendingApyHistoryPeriod)
        case withdraw
        case addFunds
        case howItWorks
        case openURL(URL)
        case close
    }
}

// MARK: - Constants

private extension LendingPositionContentView {
    enum Constants {
        static let placeholder = "$0,000.00"
        static let horizontalPadding: CGFloat = 24
        static let controlsHorizontalPadding: CGFloat = 16
        static let rowsHorizontalPadding: CGFloat = 8
        static let headerTopPadding: CGFloat = 56
        static let headerSpacing: CGFloat = 24
        static let balanceSpacing: CGFloat = 8
        static let periodSpacing: CGFloat = 8
        static let apySpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 36
        static let paragraphVerticalPadding: CGFloat = 12
        static let errorSpacing: CGFloat = 12
        static let chartHeight: CGFloat = 110
        static let amountMinScale: CGFloat = 0.5
    }
}
