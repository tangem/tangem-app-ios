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
            notificationBannerParams = nil
            start(for: viewState)
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    var notificationBannerParams: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var networkFeeAmountState: NetworkFeeAmountState = .none

    @Published
    private(set) var apyState: LoadableTextView.State = .loading

    @Published
    private(set) var minimalAmountState: LoadableTextView.State = .loading

    @Published
    private(set) var currentNetworkFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var isProcessingRequest: Bool = false

    @Published
    private(set) var isMainButtonAvailable = false

    @Published
    private(set) var apyTrend: ApyTrend = .none

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var feeCurrencyNavigator: (any FeeCurrencyNavigating)?
    private let yieldManagerInteractor: YieldManagerInteractor
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var activityState: ActivityState = .active
    private let availableBalance: Decimal

    private(set) var readMoreURL: URL = TangemBlogUrlBuilder().url(post: .fee)

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)?,
        yieldManagerInteractor: YieldManagerInteractor,
        availableBalance: Decimal,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.feeCurrencyNavigator = feeCurrencyNavigator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.availableBalance = availableBalance
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
    }

    func onAcctionTap(action: YieldAction) {
        let token = walletModel.tokenItem
        isProcessingRequest = true

        Task { @MainActor [weak self] in
            defer { self?.isProcessingRequest = false }

            do {
                switch action {
                case .approve:
                    try await self?.yieldManagerInteractor.approve(with: token)
                    self?.onBackTap()
                case .stop:
                    self?.logger.logEarningButtonStop()
                    try await self?.yieldManagerInteractor.exit(with: token)
                    self?.logger.logEarningFundsWithdrawed()
                    self?.floatingSheetPresenter.removeActiveSheet()
                }

            } catch let error where error.isCancellationError {
                // Do nothing
            } catch {
                self?.logError(error: error, action: action)
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
        }
    }

    // MARK: - Public Implementation

    func start(for viewState: ViewState) {
        Task { @MainActor in
            switch viewState {
            case .earnInfo:
                earnInfoStart()
            case .stopEarning:
                await fetchFee(for: .stop)
            case .approve:
                await fetchFee(for: .approve)
            }
        }
    }

    func getAvailableBalanceString() -> String {
        feeConverter.formatCryptoBalance(availableBalance, prefix: "a")
    }

    // MARK: - Public Implementation

    @MainActor
    func fetchFee(for action: YieldAction) async {
        networkFeeState = .loading
        notificationBannerParams = nil

        defer { getButtonAvailability() }

        do {
            let feeInCoins = switch action {
            case .approve:
                try await yieldManagerInteractor.getApproveFee()
            case .stop:
                try await yieldManagerInteractor.getExitFee()
            }

            let feeValue = feeInCoins.totalFeeAmount.value
            let convertedFee = try await feeConverter.createFeeString(from: feeValue)

            networkFeeState = .loaded(text: convertedFee)

            if feeValue > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType) {
                showNotEnoughFeeNotification()
            }

        } catch {
            networkFeeState = .noData
            showFeeErrorNotification { [weak self] in
                await self?.fetchFee(for: action)
            }
        }
    }

    func makeMyFundsSectionText() -> AttributedString {
        let tokenName = walletModel.tokenItem.name
        let symbol = walletModel.tokenItem.currencySymbol
        let fullString = Localization.yieldModuleEarnSheetProviderDescription(tokenName, symbol) + " " + Localization.commonReadMore

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
        Task { await getMinTopUp() }
        Task { await getApy() }
        Task { await checkApproval() }
        Task { await fetchChartData() }
        Task { await fetchCurrentNetworkFee() }
    }

    @MainActor
    private func getButtonAvailability() {
        switch viewState {
        case .earnInfo:
            let isDisabled = notificationBannerParams?.isApproveNeeded ?? false
            isMainButtonAvailable = !isDisabled

        case .stopEarning, .approve:
            guard case .loaded = networkFeeState else {
                isMainButtonAvailable = false
                return
            }

            if case .notEnoughFeeCurrency = notificationBannerParams {
                isMainButtonAvailable = false
                return
            }

            if case .feeUnreachable = notificationBannerParams {
                isMainButtonAvailable = false
                return
            }

            isMainButtonAvailable = true
        }
    }

    @MainActor
    private func getMinTopUp() async {
        minimalAmountState = .loading

        do {
            let minAmount = try await yieldManagerInteractor.getMinAmount()
            let formatted = try await feeConverter.createMinimalAmountString(from: minAmount)

            minimalAmountState = .loaded(text: formatted)
        } catch {
            minimalAmountState = .noData
        }
    }

    @MainActor
    private func fetchCurrentNetworkFee() async {
        currentNetworkFeeState = .loading

        guard let maxFee = await yieldManagerInteractor.getMaxFee() else {
            currentNetworkFeeState = .noData
            return
        }

        do {
            let networkFee = try await yieldManagerInteractor.getCurrentNetworkFee()
            let maxFeeFormatted = try await feeConverter.createMaxFeeString(maxFeeCurrencyFee: maxFee.0, maxFiatFee: maxFee.1)

            currentNetworkFeeState = .loaded(text: feeConverter.createCurrentNetworkFeeString(networkFee: networkFee))
            networkFeeAmountState = networkFee > maxFee.1 ? .warning(fee: maxFeeFormatted) : .normal(fee: maxFeeFormatted)

            if case .warning = networkFeeAmountState {
                logger.logEarningNoticeHighNetworkFeeShown()
            }

        } catch {
            currentNetworkFeeState = .noData
            networkFeeAmountState = .none
        }
    }

    @MainActor
    private func fetchChartData() async {
        chartState = .loading

        do {
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
    private func checkApproval() async {
        defer {
            getButtonAvailability()
        }

        guard await yieldManagerInteractor.getIsApproveRequired() else {
            activityState = .active
            return
        }

        activityState = .paused
        notificationBannerParams = .approveNeeded { [weak self] in
            self?.logger.logEarningButtonGiveApprove()
            self?.viewState = .approve
        }
    }

    private func showNotEnoughFeeNotification() {
        notificationBannerParams = .notEnoughFeeCurrency(
            feeCurrencyName: walletModel.feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: walletModel.feeTokenItem.blockchain, filled: true)
        ) { [weak self] in
            guard let self else { return }

            if let selectedUserWalletModel = userWalletRepository.selectedModel,
               let feeWalletModel = getFeeCurrencyWalletModel(in: selectedUserWalletModel) {
                onCloseTap()
                feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserWalletModel)
            }
        }
    }

    private func showFeeErrorNotification(feeFetcher: @escaping () async -> Void) {
        notificationBannerParams = .feeUnreachable { [weak self] in
            guard let self else { return }
            runTask(in: self) { vm in
                await feeFetcher()
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

extension YieldModuleInfoViewModel {
    enum NetworkFeeAmountState {
        case warning(fee: String)
        case normal(fee: String)
        case none

        var networkFeeColor: Color {
            switch self {
            case .warning:
                Colors.Text.warning
            case .normal, .none:
                Colors.Text.tertiary
            }
        }

        var networkFeeDescriptionColor: Color {
            switch self {
            case .warning:
                Colors.Text.warning
            case .normal, .none:
                Colors.Text.primary1
            }
        }

        var footerText: String {
            switch self {
            case .warning:
                // [REDACTED_TODO_COMMENT]
                ""
            case .normal:
                // [REDACTED_TODO_COMMENT]
                ""
            case .none:
                ""
            }
        }
    }
}

extension YieldModuleInfoViewModel {
    enum ApyTrend {
        case loading
        case increased
        case none
    }
}
