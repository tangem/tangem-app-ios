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

final class YieldModuleInfoViewModel: ObservableObject {
    // MARK: - Types

    enum YieldAction {
        case exit
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
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var apyState: LoadableTextView.State = .loading

    @Published
    private(set) var minimalAmountState: LoadableTextView.State = .loading

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var isProcessingRequest: Bool = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var feeCurrencyNavigator: (any FeeCurrencyNavigating)?
    private let yieldManagerInteractor: YieldManagerInteractor
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)

    // MARK: - Properties

    private(set) var activityState: ActivityState
    private let availableBalance: Decimal

    private(set) var readMoreURL: URL = TangemBlogUrlBuilder().url(post: .fee)

    var isButtonEnabled: Bool {
        switch viewState {
        case .earnInfo:
            return true

        case .stopEarning, .approve:
            switch (networkFeeState, notificationBannerParams) {
            case (.loaded, .notEnoughFeeCurrency):
                return false
            case (.loaded, .feeUnreachable):
                return false
            case (.loaded, .none):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)?,
        yieldManagerInteractor: YieldManagerInteractor,
        activityState: ActivityState,
        availableBalance: Decimal
    ) {
        self.walletModel = walletModel
        self.feeCurrencyNavigator = feeCurrencyNavigator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.activityState = activityState
        self.availableBalance = availableBalance

        viewState = .earnInfo
        start()
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
                case .exit:
                    try await self?.yieldManagerInteractor.exit(with: token)
                }

                self?.floatingSheetPresenter.removeActiveSheet()
            } catch let error where error.isCancellationError {
                // Do nothing
            } catch {
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
        }
    }

    // MARK: - Public Implementation

    @MainActor
    func fetchChartData() async {
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

    func getAvailableBalanceString() -> String {
        feeConverter.formatCryptoBalance(availableBalance, prefix: "a")
    }

    // MARK: - Public Implementation

    @MainActor
    func fetchFee(for action: YieldAction) async {
        networkFeeState = .loading
        notificationBannerParams = nil

        do {
            let feeInCoins = switch action {
            case .approve:
                try await yieldManagerInteractor.getApproveFee()
            case .exit:
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

    private func getMinTopUp() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            minimalAmountState = .loading

            do {
                let minAmount = try await yieldManagerInteractor.getMinAmount()
                let formatted = try await feeConverter.createMinimalAmountString(from: minAmount)
                minimalAmountState = .loaded(text: formatted)
            } catch {
                minimalAmountState = .noData
            }
        }
    }

    private func getApy() {
        Task { @MainActor [weak self] in
            self?.apyState = .loading

            if let apy = try? await self?.yieldManagerInteractor.getApy() {
                self?.apyState = .loaded(text: PercentFormatter().format(apy, option: .interval))
            } else {
                self?.apyState = .noData
            }
        }
    }

    private func start() {
        getMinTopUp()
        getApy()
    }

    private func showApproveSheet() {
        viewState = .approve
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
