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

    let tangemIconProvider: TangemIconProvider

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

    // MARK: - Init

    init(
        action: YieldModuleAction,
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)? = nil,
        yieldManagerInteractor: YieldManagerInteractor,
        notificationManager: YieldModuleNotificationManager,
        logger: YieldAnalyticsLogger,
        tangemIconProvider: TangemIconProvider
    ) {
        self.action = action

        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.notificationManager = notificationManager
        self.logger = logger
        self.tangemIconProvider = tangemIconProvider

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
                    try await self?.yieldManagerInteractor.exit(with: token)
                    self?.logger.logEarningFundsWithdrawed()

                case .none:
                    break
                }

                self?.coordinator?.dismiss()
            } catch let error where error.isCancellationError {
                // Do nothing
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
        networkFeeState = networkFeeState.withFeeState(.loading)

        Task {
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

            let isHighFee = feeValue > walletModel.getFeeCurrencyBalance()

            if isHighFee {
                logger.logEarningNoticeNotEnoughFeeShown()
                showNotEnoughFeeNotification()
            }

            isActionButtonAvailable = !isHighFee
        } catch {
            isActionButtonAvailable = false
            networkFeeState = networkFeeState.withFeeState(.noData)

            let notification = createFeeErrorNotification(yieldAction: action)

            networkFeeNotification = notification
        }
    }

    private func showNotEnoughFeeNotification() {
        networkFeeNotification = createNotEnoughFeeNotification(walletModel: walletModel)
    }

    private func setNetworkFeeStateLoading() {
        networkFeeNotification = nil
        networkFeeState = networkFeeState.withFeeState(.loading)
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
        notificationManager.createFeeUnreachableNotification {
            Task { @MainActor [weak self] in
                self?.setNetworkFeeStateLoading()
                _ = try? await self?.walletModel.update(silent: true).async()
                await self?.fetchNetworkFee(for: yieldAction)
            }
        }
    }
}
