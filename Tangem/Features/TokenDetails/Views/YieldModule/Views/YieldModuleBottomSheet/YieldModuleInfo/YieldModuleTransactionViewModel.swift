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

final class YieldModuleTransactionViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

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

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var action: YieldModuleAction
    private(set) var readMoreURL: URL = TangemBlogUrlBuilder().url(post: .fee)

    private var loadedFee: LoadedFee?

    // MARK: - Init

    init(
        action: YieldModuleAction,
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)? = nil,
        yieldManagerInteractor: YieldManagerInteractor,
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

        start()
    }

    // MARK: - Public Implementation

    func openReadMore() {
        Task { @MainActor [weak self, readMoreURL] in
            self?.coordinator?.openUrl(url: readMoreURL)
        }
    }

    func onBackTap() {
        coordinator?.closeBottomSheet()
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

        do {
            let loadedFee = try await loadFee(for: action)
            let feeText = try await feeConverter.createFeeString(from: loadedFee.total)

            update(with: loadedFee, feeText: feeText)
        } catch {
            networkFeeState = networkFeeState.withFeeState(.noData)
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
            let exitFee = try await yieldManagerInteractor.getExitFee().totalFeeAmount.value
            let claim = mayClaimRewards ? await prepareWithdrawalClaim() : nil

            return .withdrawal(exitFee: exitFee, claim: claim)
        }
    }

    @MainActor
    private func update(with loadedFee: LoadedFee, feeText: String) {
        self.loadedFee = loadedFee
        networkFeeState = networkFeeState.withFeeState(.loaded(text: feeText))

        let feeCurrencyBalance = walletModel.getFeeCurrencyBalance()
        let isAffordable = loadedFee.total <= feeCurrencyBalance

        if !isAffordable {
            showNotEnoughFeeNotification(feeCurrencyBalance: feeCurrencyBalance)
        }

        isActionButtonAvailable = isAffordable
    }

    private func showNotEnoughFeeNotification(feeCurrencyBalance: Decimal) {
        logger.logEarningNoticeNotEnoughFeeShown(feeCurrencyBalance: feeCurrencyBalance)
        networkFeeNotification = createNotEnoughFeeNotification(walletModel: walletModel)
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
        case withdrawal(exitFee: Decimal, claim: YieldIncentivesClaimInteractor.PreparedClaim?)

        var total: Decimal {
            switch self {
            case .approve(let fee):
                fee
            case .withdrawal(let exitFee, let claim):
                exitFee + (claim?.fee.totalFeeAmount.value ?? .zero)
            }
        }

        var batchedWithdrawal: (claim: YieldIncentivesClaimInteractor.PreparedClaim, exitFee: Decimal)? {
            guard case .withdrawal(let exitFee, let claim) = self, let claim else {
                return nil
            }

            return (claim, exitFee)
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleTransactionViewModel: FloatingSheetContentViewModel {}

// MARK: - Notification Builders

private extension YieldModuleTransactionViewModel {
    func createNotEnoughFeeNotification(walletModel: any WalletModel) -> YieldModuleNotificationBannerParams {
        notificationManager.createNotEnoughFeeCurrencyNotification { [weak self] in
            self?.coordinator?.openFeeCurrency(walletModel: walletModel)
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
