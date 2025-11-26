//
//  YieldInfoBottomSheetViewModel.swift
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

final class YieldModuleInfoViewModel: ObservableObject {
    // MARK: - Types

    enum YieldAction {
        case stop
        case approve
    }

    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    @Injected(\.floatingSheetPresenter)
    var floatingSheetPresenter: FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
            networkFeeNotification = nil
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    private(set) var earnInfoNotifications = [YieldModuleNotificationBannerParams]()

    @Published
    private(set) var networkFeeNotification: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var apyState: LoadableTextView.State = .loading

    @Published
    private(set) var networkFeeState: YieldFeeSectionState = .init().withLinkActive(true)

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
    private(set) var isProcessingRequest: Bool = false

    @Published
    private(set) var isActionButtonAvailable = false

    @Published
    private(set) var apyTrend: ApyTrend = .none

    private var maxFee: String?

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var feeCurrencyNavigator: (any FeeCurrencyNavigating)?
    private let yieldManagerInteractor: YieldManagerInteractor
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var activityState: ActivityState = .active
    private(set) var readMoreURL = URL(string: "https://tangem.com/en/blog/post/yield-mode")!
    private var minimalTopupAmountInFiat: Decimal?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)?,
        yieldManagerInteractor: YieldManagerInteractor,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.feeCurrencyNavigator = feeCurrencyNavigator
        self.yieldManagerInteractor = yieldManagerInteractor
        notificationManager = YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
        self.logger = logger

        viewState = .earnInfo
        start(for: viewState)
        logger.logEarningInProgressScreenOpened()
    }

    // MARK: - Navigation

    func onCloseTap() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onBackTap() {
        previousState.map { viewState = $0 }
    }

    func onShowStopEarningSheet() {
        logger.logEarningStopScreenOpened()
        viewState = .stopEarning
        start(for: .stopEarning)
        networkFeeState = networkFeeState.withFooterText(Localization.yieldModuleStopEarningSheetFeeNote)
    }

    // MARK: - Public Implementation

    func start(for viewState: ViewState) {
        Task { @MainActor in
            switch viewState {
            case .earnInfo:
                earnInfoStart()
            case .stopEarning:
                await fetchNetworkFee(for: .stop)
            case .approve:
                await fetchNetworkFee(for: .approve)
            }
        }
    }

    func onActionTap(action: YieldAction) {
        let token = walletModel.tokenItem
        isProcessingRequest = true

        Task { @MainActor [weak self] in
            defer { self?.isProcessingRequest = false }

            do {
                switch action {
                case .approve:
                    try await self?.yieldManagerInteractor.approve(with: token)

                case .stop:
                    self?.logger.logEarningButtonStop()
                    try await self?.yieldManagerInteractor.exit(with: token)
                    self?.logger.logEarningFundsWithdrawed()
                }

                self?.floatingSheetPresenter.removeActiveSheet()
            } catch let error where error.isCancellationError {
                // Do nothing
            } catch {
                self?.logError(error: error, action: action)
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
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

    private func logError(error: Error, action: YieldAction) {
        let analyticsAction: YieldAnalyticsAction = switch action {
        case .approve: .approve
        case .stop: .stop
        }

        logger.logEarningErrors(action: analyticsAction, error: error)
    }

    private func earnInfoStart() {
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
    private func fetchNetworkFee(for action: YieldAction) async {
        networkFeeState = networkFeeState.withFeeState(.loading)
        networkFeeNotification = nil
        isActionButtonAvailable = false

        do {
            let feeInCoins = switch action {
            case .approve:
                try await yieldManagerInteractor.getApproveFee()
            case .stop:
                try await yieldManagerInteractor.getExitFee()
            }

            let feeValue = feeInCoins.totalFeeAmount.value
            let convertedFee = try await feeConverter.createFeeString(from: feeValue)

            networkFeeState = networkFeeState.withFeeState(.loaded(text: convertedFee))

            let isHighFee = feeValue > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType)

            if isHighFee {
                logger.logEarningNoticeNotEnoughFeeShown()
                networkFeeNotification = createNotEnoughFeeNotification()
            }

            isActionButtonAvailable = !isHighFee
        } catch {
            isActionButtonAvailable = false
            networkFeeState = networkFeeState.withFeeState(.noData)

            let notification = createFeeErrorNotification(yieldAction: action)

            networkFeeNotification = notification
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
            let estimatedFee = try await yieldManagerInteractor.getCurrentNetworkFee()
            let estimatedFeeFormatted = try await feeConverter.makeFormattedMinimalFee(from: estimatedFee)

            let minAmount = try await yieldManagerInteractor.getMinAmount()
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

        if let undepositedAmount {
            guard let minimalTopupAmountInFiat,
                  let undepositedAmountInFiat = try? await feeConverter.convertToFiat(undepositedAmount, currency: .token),
                  undepositedAmountInFiat < minimalTopupAmountInFiat
            else {
                let formatted = feeConverter.formatDecimal(undepositedAmount)
                earnInfoNotifications.append(createHasUndepositedAmountsNotification(undepositedAmount: formatted))
                return
            }
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

extension YieldModuleInfoViewModel {
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

// MARK: - FloatingSheetContentViewModel

extension YieldModuleInfoViewModel: FloatingSheetContentViewModel {}

// MARK: - ActivityState

extension YieldModuleInfoViewModel {
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

        var transferMode: String {
            switch self {
            case .active:
                Localization.yieldModuleTransferModeAutomatic
            case .paused:
                Localization.yieldModuleStatusPaused
            }
        }
    }
}

// MARK: - ApyTrend

extension YieldModuleInfoViewModel {
    enum ApyTrend {
        case loading
        case increased
        case none
    }
}

// MARK: - Notification Builders

private extension YieldModuleInfoViewModel {
    func createApproveRequiredNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createApproveRequiredNotification { [weak self] in
            guard let self else { return }
            logger.logEarningButtonGiveApprove()
            networkFeeState = networkFeeState.withFooterText(Localization.yieldModuleApproveSheetFeeNote)
            viewState = .approve
            start(for: .approve)
        }
    }

    func createHasUndepositedAmountsNotification(undepositedAmount: String) -> YieldModuleNotificationBannerParams {
        logger.logEarningNoticeAmountNotDepositedShown()
        return notificationManager.createHasUndepositedAmountsNotification(undepositedAmount: undepositedAmount)
    }

    func createNotEnoughFeeNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createNotEnoughFeeCurrencyNotification { [weak self] in
            guard let self else { return }

            if let selectedUserWalletModel = userWalletRepository.selectedModel,
               let feeWalletModel = getFeeCurrencyWalletModel(in: selectedUserWalletModel) {
                onCloseTap()
                feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserWalletModel)
            }
        }
    }

    func createFeeErrorNotification(yieldAction: YieldAction) -> YieldModuleNotificationBannerParams {
        notificationManager.createFeeUnreachableNotification { [weak self] in
            Task { @MainActor [weak self] in
                await self?.fetchNetworkFee(for: yieldAction)
            }
        }
    }
}
