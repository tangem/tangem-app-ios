//
//  YieldModuleStartViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemSdk

final class YieldModuleStartViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    var alert: AlertBinder?

    @Published
    private(set) var notificationBannerParams: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var tokenFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var maximumFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var minimalAmountState: LoadableTextView.State = .loading

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var isProcessingStartRequest: Bool = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModulePromoCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor
    private let logger: YieldAnalyticsLogger

    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)

    // MARK: - Properties

    private(set) var maximumFee: Decimal = 0

    var isButtonEnabled: Bool {
        switch viewState {
        case .startEarning:
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

        default:
            return true
        }
    }

    var isNavigationToFeePolicyEnabled: Bool {
        guard case .startEarning = viewState else { return true }
        guard case .loaded = networkFeeState else { return false }

        if case .feeUnreachable = notificationBannerParams {
            return false
        }

        return true
    }

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        viewState: ViewState,
        coordinator: YieldModulePromoCoordinator?,
        yieldManagerInteractor: YieldManagerInteractor,
        logger: YieldAnalyticsLogger
    ) {
        self.viewState = viewState
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.logger = logger
    }

    // MARK: - Navigation

    @MainActor
    func onCloseTap() {
        floatingSheetPresenter.removeActiveSheet()
        runTask(in: self) { vm in
            await vm.yieldManagerInteractor.clearAll()
        }
    }

    @MainActor
    func onShowFeePolicy() {
        logger.logEarningButtonFeePolicy()
        viewState = .feePolicy
    }

    @MainActor
    func onStartEarnTap() {
        let token = walletModel.tokenItem
        isProcessingStartRequest = true
        logger.logEarningButtonStart()

        Task { @MainActor [weak self] in
            defer { self?.isProcessingStartRequest = false }

            do {
                try await self?.yieldManagerInteractor.enter(with: token)
                self?.logger.logEarningFundsEarned()
                self?.coordinator?.dismiss()
            } catch let error where error.isCancellationError {
                // Do nothing
            } catch {
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
        }
    }

    @MainActor
    func onBackAction() {
        previousState.map { viewState = $0 }
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

    func fetchFees() {
        Task { await fetchNetworkFee() }
        Task { await fetchMaximumFee() }
        Task { await fetchMinimalAmount() }
    }

    @MainActor
    func fetchMinimalAmount() async {
        minimalAmountState = .loading

        do {
            let minimalAmountInTokens = try await yieldManagerInteractor.getMinAmount()
            let formatted = try await feeConverter.createMinimalAmountString(from: minimalAmountInTokens)
            minimalAmountState = .loaded(text: formatted)
        } catch {
            minimalAmountState = .noData
        }
    }

    @MainActor
    func fetchMaximumFee() async {
        maximumFeeState = .loading

        if let (maxFeeCurrencyFee, maxFiatFee) = await yieldManagerInteractor.getMaxFee(),
           let feeInTokens = try? await feeConverter.createMaxFeeString(maxFeeCurrencyFee: maxFeeCurrencyFee, maxFiatFee: maxFiatFee) {
            maximumFeeState = .loaded(text: feeInTokens)
        } else {
            maximumFeeState = .noData
        }
    }

    @MainActor
    func fetchNetworkFee() async {
        tokenFeeState = .loading
        networkFeeState = .loading
        notificationBannerParams = nil

        do {
            let feeInCoins = try await yieldManagerInteractor.getEnterFee()
            let feeValue = feeInCoins.totalFeeAmount.value

            let convertedFee = try await feeConverter.createFeeString(from: feeValue)
            let feeInTokens = try await feeConverter.makeFeeInTokenString(from: feeValue)

            networkFeeState = .loaded(text: convertedFee)
            tokenFeeState = .loaded(text: feeInTokens)

            if feeValue > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType) {
                showNotEnoughFeeNotification()
            }

        } catch {
            tokenFeeState = .noData
            networkFeeState = .noData
            showFeeErrorNotification()
        }
    }

    // MARK: - Private Implementation

    private func showNotEnoughFeeNotification() {
        notificationBannerParams = .notEnoughFeeCurrency(
            feeCurrencyName: walletModel.feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: walletModel.feeTokenItem.blockchain, filled: true)
        ) { [weak self] in
            if let selectedUserWalletModel = self?.userWalletRepository.selectedModel,
               let feeWalletModel = self?.getFeeCurrencyWalletModel(in: selectedUserWalletModel) {
                self?.onCloseTap()
                self?.coordinator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserWalletModel)
            }
        }

        logger.logEarningNoticeNotEnoughFeeShown()
    }

    private func showFeeErrorNotification() {
        notificationBannerParams = .feeUnreachable { [weak self] in
            guard let self else { return }
            runTask(in: self) { vm in
                await vm.fetchNetworkFee()
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

// MARK: - View State

extension YieldModuleStartViewModel {
    enum ViewState: Identifiable, Equatable {
        case rateInfo
        case feePolicy
        case startEarning

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .feePolicy:
                "feePolicy"
            case .startEarning:
                "startEarning"
            }
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleStartViewModel: FloatingSheetContentViewModel {}
