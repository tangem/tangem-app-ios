//
//  YieldModuleTransactionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemUI
import SwiftUI
import Combine

final class YieldModuleTransactionViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    // MARK: - ViewState

    let signingActionButtonType: SigningActionButtonViewType

    // MARK: - Published

    @Published
    private(set) var networkFeeNotification: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: YieldFeeSectionState = .init().withLinkActive(true)

    @Published
    private(set) var isProcessingRequest: Bool = false

    @Published
    private(set) var isActionButtonAvailable = false

    @Published
    private(set) var isSelectingFeeToken = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    let feeTokenSelector: YieldFeeTokenSelector?
    private weak var coordinator: YieldModuleActiveCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var action: YieldModuleAction
    private(set) var readMoreURL: URL = TangemBlogUrlBuilder().url(post: .fee)

    private var loadedFee: LoadedFee?
    private var selectedTokenFee: TokenFee?
    private var bag = Set<AnyCancellable>()

    private var isGaslessFeeSelected: Bool {
        selectedTokenFee.map { $0.tokenItem != walletModel.feeTokenItem } ?? false
    }

    // MARK: - Init

    init(
        action: YieldModuleAction,
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)? = nil,
        yieldManagerInteractor: YieldManagerInteractor,
        gaslessFeeService: YieldGaslessFeeService? = nil,
        notificationManager: YieldModuleNotificationManager,
        logger: YieldAnalyticsLogger,
        signingActionButtonType: SigningActionButtonViewType
    ) {
        self.action = action

        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.notificationManager = notificationManager
        self.logger = logger
        self.signingActionButtonType = signingActionButtonType

        feeTokenSelector = gaslessFeeService.map {
            YieldFeeTokenSelector(gaslessFeeService: $0, coinFeeTokenItem: walletModel.feeTokenItem)
        }

        bindFeeTokenSelector()
        start()
    }

    // MARK: - Public Implementation

    func openReadMore() {
        Task { @MainActor [weak self, readMoreURL] in
            self?.coordinator?.openUrl(url: readMoreURL)
        }
    }

    func onBackTap() {
        guard !isSelectingFeeToken else {
            dismissFeeTokenSelection()
            return
        }

        coordinator?.closeBottomSheet()
    }

    func onFeeTap() {
        presentFeeTokenSelection()
    }

    func onActionTap() {
        let token = walletModel.tokenItem
        isProcessingRequest = true

        Task { @MainActor [weak self] in
            defer { self?.isProcessingRequest = false }

            do {
                switch self?.action {
                case .approve:
                    try await self?.yieldManagerInteractor.approve(with: token)

                case .stop:
                    self?.logger.logEarningButtonStop()

                    if let batchedWithdrawal = self?.loadedFee?.batchedWithdrawal {
                        let feeCurrencyBalance = self?.walletModel.getFeeCurrencyBalance() ?? .zero

                        try await self?.yieldManagerInteractor.exitClaimingRewards(
                            with: token,
                            prepared: batchedWithdrawal.claim
                        ) { claimFee in claimFee.value + batchedWithdrawal.exitFee <= feeCurrencyBalance }
                    } else {
                        try await self?.yieldManagerInteractor.exit(with: token)
                    }

                    self?.logger.logEarningFundsWithdrawed()

                case .none:
                    break
                }

                self?.coordinator?.dismiss()
            } catch let error where error.isCancellationError {
                // Do nothing
            } catch let error as YieldIncentivesClaimInteractor.ClaimError {
                guard let self else { return }

                await handle(claimError: error)
            } catch {
                self?.logError(error: error)
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
        }
    }

    // MARK: - Private Implementation

    private func start() {
        configureFeeSectionFooter()
        log()

        Task { [weak self, action] in
            await self?.fetchNetworkFee(for: action)
        }
    }

    @MainActor
    private func prepareWithdrawalClaim() async -> YieldIncentivesClaimInteractor.PreparedClaim? {
        do {
            return try await yieldManagerInteractor.prepareWithdrawalClaim()
        } catch let error as YieldIncentivesClaimInteractor.ClaimError where error.isClaimNoLongerAvailable {
            return nil
        } catch {
            AppLogger.error("Yield withdrawal claim preparation failed", error: error)
            return nil
        }
    }

    @MainActor
    private func handle(claimError: YieldIncentivesClaimInteractor.ClaimError) async {
        switch claimError {
        case .insufficientFee, .preparationExpired, .claimAlreadyInFlight,
             .validationFailed, .rewardsUnavailable, .moduleUnavailable:
            await fetchNetworkFee(for: action)
        case .submissionUnresolved(let underlying):
            logError(error: claimError)
            alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: underlying.localizedDescription))

            await fetchNetworkFee(for: action)
        }
    }

    private func configureFeeSectionFooter() {
        let footerText: String

        switch action {
        case .stop:
            footerText = Localization.yieldModuleStopEarningSheetFeeNote
        case .approve:
            footerText = Localization.yieldModuleApproveSheetFeeNote
        }

        networkFeeState = networkFeeState.withFooterText(footerText)
    }

    private func log() {
        if case .stop = action {
            logger.logEarningStopScreenOpened()
        }
    }

    private func logError(error: Error) {
        let analyticsAction: YieldAnalyticsAction = switch action {
        case .approve: .approve
        case .stop: .stop
        }

        logger.logEarningErrors(action: analyticsAction, error: error)
    }

    @MainActor
    private func fetchNetworkFee(for action: YieldModuleAction) async {
        isActionButtonAvailable = false
        networkFeeState = networkFeeState.withFeeState(.loading)
        networkFeeNotification = nil
        loadedFee = nil
        feeTokenSelector?.resetFees()

        do {
            let loadedFee = try await loadFee(for: action)
            let feeText = try await feeConverter.createFeeString(from: loadedFee.total)

            networkFeeState = networkFeeState.withFeeState(.loaded(text: feeText))

            if let feeTokenSelector, !loadedFee.withdrawalTransactionFees.isEmpty {
                await feeTokenSelector.updateFees(for: loadedFee.withdrawalTransactionFees, nativeFeeValue: loadedFee.total)
            }

            self.loadedFee = loadedFee
            applyFeeState()
        } catch {
            networkFeeState = networkFeeState.withFeeState(.noData)
            feeTokenSelector?.failFees(error: error)
            networkFeeNotification = createFeeErrorNotification(yieldAction: action)
        }
    }

    @MainActor
    private func loadFee(for action: YieldModuleAction) async throws -> LoadedFee {
        switch action {
        case .approve:
            let approveFee = try await yieldManagerInteractor.getApproveFee().totalFeeAmount.value

            return .approve(approveFee)

        case .stop(_, let mayClaimRewards):
            let exitFee = try await yieldManagerInteractor.getExitFee()
            let claim = mayClaimRewards ? await prepareWithdrawalClaim() : nil

            return .withdrawal(exitFee: exitFee, claim: claim)
        }
    }

    private func bindFeeTokenSelector() {
        feeTokenSelector?.selectedFeePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, tokenFee in
                viewModel.selectedTokenFee = tokenFee
                viewModel.applyFeeState()
            }
            .store(in: &bag)
    }

    private func applyFeeState() {
        guard let loadedFee else {
            return
        }

        if case .loading = selectedTokenFee?.value {
            networkFeeNotification = nil
            isActionButtonAvailable = false
            return
        }

        if let selectedTokenFee, isGaslessFeeSelected {
            applyGaslessFeeState(selectedTokenFee)
            return
        }

        let feeCurrencyBalance = walletModel.getFeeCurrencyBalance()
        let isAffordable = loadedFee.total <= feeCurrencyBalance

        if !isAffordable, networkFeeNotification == nil {
            logger.logEarningNoticeNotEnoughFeeShown(feeCurrencyBalance: feeCurrencyBalance)
        }

        networkFeeNotification = isAffordable ? nil : createNotEnoughFeeNotification(walletModel: walletModel)
        isActionButtonAvailable = isAffordable
    }

    private func applyGaslessFeeState(_ tokenFee: TokenFee) {
        switch tokenFee.value {
        case .success:
            networkFeeNotification = nil
            isActionButtonAvailable = true
        case .failure(let error):
            if case .notEnoughGaslessFeeBalance = error as? TokenFeeProviderError {
                networkFeeNotification = createNotEnoughFeeTokenNotification(feeTokenItem: tokenFee.tokenItem)
            } else {
                networkFeeNotification = createFeeErrorNotification(yieldAction: action)
            }
            isActionButtonAvailable = false
        case .loading:
            networkFeeNotification = nil
            isActionButtonAvailable = false
        }
    }

    private func setNetworkFeeStateLoading() {
        networkFeeNotification = nil
        networkFeeState = networkFeeState.withFeeState(.loading)
    }
}

// MARK: - Loaded Fee

private extension YieldModuleTransactionViewModel {
    enum LoadedFee {
        case approve(Decimal)
        case withdrawal(exitFee: YieldTransactionFee, claim: YieldIncentivesClaimInteractor.PreparedClaim?)

        var total: Decimal {
            switch self {
            case .approve(let fee):
                fee
            case .withdrawal(let exitFee, let claim):
                exitFee.totalFeeAmount.value + (claim?.fee.totalFeeAmount.value ?? .zero)
            }
        }

        var withdrawalTransactionFees: [YieldTransactionFee] {
            guard case .withdrawal(let exitFee, let claim) = self else {
                return []
            }

            return [claim?.fee, exitFee].compactMap { $0 }
        }

        var batchedWithdrawal: (claim: YieldIncentivesClaimInteractor.PreparedClaim, exitFee: Decimal)? {
            guard case .withdrawal(let exitFee, let claim) = self, let claim else {
                return nil
            }

            return (claim, exitFee.totalFeeAmount.value)
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleTransactionViewModel: FloatingSheetContentViewModel {}

// MARK: - FeeSelectorTokensRoutable

extension YieldModuleTransactionViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        feeTokenSelector?.userDidSelectFeeToken(tokenFeeProvider: tokenFeeProvider)
        dismissFeeTokenSelection()
    }
}

// MARK: - Navigation Helpers

private extension YieldModuleTransactionViewModel {
    func presentFeeTokenSelection() {
        guard let feeTokenSelector else { return }

        feeTokenSelector.setup(router: self)
        isSelectingFeeToken = true
    }

    func dismissFeeTokenSelection() {
        isSelectingFeeToken = false
    }
}

// MARK: - Notification Builders

private extension YieldModuleTransactionViewModel {
    func createNotEnoughFeeNotification(walletModel: any WalletModel) -> YieldModuleNotificationBannerParams {
        notificationManager.createNotEnoughFeeCurrencyNotification { [weak self] in
            self?.coordinator?.openFeeCurrency(walletModel: walletModel)
        }
    }

    func createNotEnoughFeeTokenNotification(feeTokenItem: TokenItem) -> YieldModuleNotificationBannerParams {
        let feeWalletModel = walletModel.account?.walletModelsManager.walletModels.first { $0.tokenItem == feeTokenItem }

        return notificationManager.createNotEnoughFeeTokenNotification(feeTokenItem: feeTokenItem) { [weak self] in
            guard let feeWalletModel else { return }
            self?.coordinator?.openFeeCurrency(walletModel: feeWalletModel)
        }
    }

    func createFeeErrorNotification(yieldAction: YieldModuleAction) -> YieldModuleNotificationBannerParams {
        notificationManager.createFeeUnreachableNotification { [weak self] in
            Task { @MainActor in
                self?.setNetworkFeeStateLoading()
                await self?.walletModel.update(silent: true, options: .balances)
                await self?.fetchNetworkFee(for: yieldAction)
            }
        }
    }
}
