//
//  YieldModuleActiveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemSdk
import SwiftUI

final class YieldModuleActiveViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - Published

    @Published
    private(set) var earnInfoNotifications = [YieldModuleNotificationBannerParams]()

    @Published
    private(set) var apyState: LoadableTextView.State = .loading

    @Published
    private(set) var minimalAmountState: YieldFeeSectionState = .init()

    @Published
    private(set) var estimatedFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var availableBalanceState: YieldFeeSectionState = .init()

    @Published
    private(set) var earInfoFooterText: AttributedString?

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var apyTrend: ApyTrend = .none

    private var maxFee: String?

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private lazy var dustFilter = YieldModuleDustFilter(feeConverter: feeConverter)

    private let transactionFlowFactory: YieldModuleTransactionFlowFactory
    private let yieldManagerInteractor: YieldManagerInteractor
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var activityState: ActivityState = .active
    private(set) var readMoreURL = URL(string: "https://tangem.com/en/blog/post/yield-mode")!
    private var minimalTopupAmountInFiat: Decimal?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        transactionFlowFactory: YieldModuleTransactionFlowFactory,
        yieldManagerInteractor: YieldManagerInteractor,
        notificationManager: YieldModuleNotificationManager,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.transactionFlowFactory = transactionFlowFactory
        self.yieldManagerInteractor = yieldManagerInteractor
        self.logger = logger
        self.notificationManager = notificationManager

        logger.logEarningInProgressScreenOpened()

        start()
    }

    // MARK: - Navigation

    func onBackButtonTap() {
        coordinator?.dismiss()
    }

    func onShowStopEarningSheet() {
        coordinator?.openBottomSheet(
            viewModel: transactionFlowFactory.makeTransactionViewModel(
                action: .stop(tokenName: walletModel.tokenItem.name)
            )
        )
    }

    // MARK: - Public Implementation

    func openReadMore() {
        let url = readMoreURL
        Task { @MainActor [weak self] in
            self?.coordinator?.openUrl(url: url)
        }
    }

    func makeMyFundsSectionText() -> AttributedString {
        let symbol = walletModel.tokenItem.currencySymbol
        let prefixedSymbol = "a\(walletModel.tokenItem.currencySymbol)"
        let fullString = Localization.yieldModuleEarnSheetProviderDescription(symbol, prefixedSymbol) + " " + Localization.commonReadMore

        var attr = AttributedString(fullString)
        attr.font = Fonts.Regular.caption1
        attr.foregroundColor = Colors.Text.tertiary

        if let range = attr.range(of: Localization.commonReadMore) {
            attr[range].foregroundColor = Colors.Text.accent
            attr[range].link = readMoreURL
        }

        return attr
    }

    // MARK: - Private Implementation

    private func start() {
        Task { await getAvailableFunds() }
        Task {
            await getEarnInfoFees()
            await checkWarnings()
        }
        Task { await getApy() }
        Task { await fetchChartData() }
    }

    @MainActor
    private func getAvailableFunds() async {
        if let availableBalance = await yieldManagerInteractor.getAvailableBalance() {
            availableBalanceState = availableBalanceState.withFeeState(
                .loaded(text: feeConverter.formatCryptoBalance(availableBalance, prefix: "a"))
            )
        } else {
            availableBalanceState = availableBalanceState.withFeeState(.noData)
        }
    }

    @MainActor
    private func getEarnInfoFees() async {
        minimalAmountState = minimalAmountState.withFeeState(.loading)
        estimatedFeeState = estimatedFeeState.withFeeState(.loading)
        maxFee = nil
        minimalTopupAmountInFiat = nil

        guard let maxFeeNative = await yieldManagerInteractor.getMaxFeeNative() else {
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            minimalAmountState = minimalAmountState.withFeeState(.noData)
            return
        }

        do {
            let feeParameters = try await yieldManagerInteractor.getCurrentFeeParameters()
            let estimatedFee = try await yieldManagerInteractor.getCurrentNetworkFee(feeParameters: feeParameters)
            let estimatedFeeFormatted = try await feeConverter.makeFormattedMinimalFee(from: estimatedFee)

            let minAmount = try await yieldManagerInteractor.getMinAmount(feeParameters: feeParameters)
            let minAmountFormatted = try await feeConverter.makeFormattedMinimalFee(from: minAmount)

            minimalTopupAmountInFiat = minAmount

            let maxFeeInFiat = try await feeConverter.convertToFiat(maxFeeNative, currency: .fee)
            let maxFeeFormatted = try await feeConverter.makeFormattedMaximumFee(maxFeeNative: maxFeeNative)

            let isHighFee = estimatedFee > maxFeeInFiat

            if isHighFee {
                logger.logEarningNoticeHighNetworkFeeShown()
            }

            estimatedFeeState = estimatedFeeState.withFeeState(.loaded(text: estimatedFeeFormatted.fiatFee)).withHighlighted(isHighFee)
            minimalAmountState = minimalAmountState.withFeeState(.loaded(text: minAmountFormatted.fiatFee))

            let footerBuilder = YieldInfoFooterBuilder()

            let footerText: AttributedString = if isHighFee {
                footerBuilder.buildForHighFee(
                    maxFeeFiat: maxFeeFormatted.fiatFee,
                    minFeeFiat: minAmountFormatted.fiatFee,
                    minFeeCrypto: minAmountFormatted.cryptoFee
                )
            } else {
                footerBuilder.build(
                    estimatedFeeFiat: estimatedFeeFormatted.fiatFee,
                    estimatedFeeCrypto: estimatedFeeFormatted.cryptoFee,
                    maxFeeFiat: maxFeeFormatted.fiatFee,
                    maxFeeCrypto: maxFeeFormatted.cryptoFee,
                    minFeeFiat: minAmountFormatted.fiatFee,
                    minFeeCrypto: minAmountFormatted.cryptoFee
                )
            }

            earInfoFooterText = footerText
        } catch {
            minimalAmountState = minimalAmountState.withFeeState(.noData)
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            maxFee = nil
            earInfoFooterText = nil
        }
    }

    @MainActor
    private func fetchChartData() async {
        chartState = .loading

        do {
            try await Task.sleep(seconds: 0.5)
            let chartData = try await yieldManagerInteractor.getChartData()
            chartState = .loaded(chartData)
        } catch {
            chartState = .error(action: { [weak self] in
                await self?.fetchChartData()
            })
        }
    }

    @MainActor
    private func getApy() async {
        apyState = .loading
        apyTrend = .loading

        if let apy = try? await yieldManagerInteractor.getApy() {
            apyState = .loaded(text: PercentFormatter().format(apy, option: .staking))
            apyTrend = .increased
        } else {
            apyTrend = .none
            apyState = .noData
        }
    }

    @MainActor
    private func checkWarnings() async {
        earnInfoNotifications = []

        activityState = .active

        let isApproveRequired = await yieldManagerInteractor.getIsApproveRequired()
        let undepositedAmount = await yieldManagerInteractor.getUndepositedAmounts()

        if isApproveRequired {
            activityState = .paused
            earnInfoNotifications.append(createApproveRequiredNotification())
        }

        if let undepositedAmount = await dustFilter.filterUndepositedAmount(
            undepositedAmount,
            minimalTopupAmountInFiat: minimalTopupAmountInFiat
        ) {
            let formatted = feeConverter.formatDecimal(undepositedAmount)
            earnInfoNotifications.append(createHasUndepositedAmountsNotification(undepositedAmount: formatted))
            logger.logEarningNoticeAmountNotDepositedShown()
        }
    }

    private func getFeeCurrencyWalletModel(in userWalletModel: any UserWalletModel) -> (any WalletModel)? {
        guard let selectedUserModel = userWalletRepository.selectedModel,
              let feeCurrencyWalletModel = selectedUserModel.walletModelsManager.walletModels.first(where: {
                  $0.tokenItem == walletModel.feeTokenItem
              })
        else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return nil
        }

        return feeCurrencyWalletModel
    }
}

// MARK: - View State

extension YieldModuleActiveViewModel {
    enum ViewState: Identifiable, Equatable {
        case earnInfo
        case stopEarning
        case approve

        var id: String {
            switch self {
            case .earnInfo:
                "earnInfo"
            case .stopEarning:
                "stopEarning"
            case .approve:
                "approve"
            }
        }
    }
}

// MARK: - ActivityState

extension YieldModuleActiveViewModel {
    enum ActivityState: Equatable {
        case active
        case paused

        var description: String {
            switch self {
            case .active:
                Localization.yieldModuleStatusActive
            case .paused:
                Localization.yieldModuleStatusPaused
            }
        }
    }
}

// MARK: - ApyTrend

extension YieldModuleActiveViewModel {
    enum ApyTrend {
        case loading
        case increased
        case none
    }
}

// MARK: - Notification Builders

private extension YieldModuleActiveViewModel {
    func createApproveRequiredNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createApproveRequiredNotification { [weak self] in
            guard let self else { return }
            logger.logEarningButtonGiveApprove()
            coordinator?.openBottomSheet(viewModel: transactionFlowFactory.makeTransactionViewModel(action: .approve))
        }
    }

    func createHasUndepositedAmountsNotification(undepositedAmount: String) -> YieldModuleNotificationBannerParams {
        notificationManager.createHasUndepositedAmountsNotification(undepositedAmount: undepositedAmount)
    }
}
