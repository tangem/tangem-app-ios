//
//  DynamicAddressesCompoundTransactionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemAssets
import TangemLocalization

final class DynamicAddressesCompoundTransactionViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let feeCompactViewModel: FeeCompactViewModel

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon? = .trailing(Assets.tangemIcon)
    @Published private(set) var needsHoldToConfirm: Bool = false

    private let transferModel: TransferModel
    private let notificationManager: SendNotificationManager
    private let walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider
    private let analyticsLogger: DynamicAddressesAnalyticsLogger
    private let sendAlertBuilder: SendAlertBuilder = CommonSendAlertBuilder()
    private let onFinish: () -> Void

    private var sendingTask: Task<Void, Never>?

    init(
        transferModel: TransferModel,
        notificationManager: SendNotificationManager,
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        analyticsLogger: DynamicAddressesAnalyticsLogger,
        onFinish: @escaping () -> Void
    ) {
        self.transferModel = transferModel
        self.notificationManager = notificationManager
        self.walletModelDynamicAddressesProvider = walletModelDynamicAddressesProvider
        self.analyticsLogger = analyticsLogger
        self.onFinish = onFinish

        feeCompactViewModel = FeeCompactViewModel(showsLeadingIcon: false)
        feeCompactViewModel.bind(input: transferModel)

        bind()
        transferModel.updateFees()
    }

    func confirm() {
        analyticsLogger.logButtonDisableDynamicAddresses()

        sendingTask?.cancel()
        sendingTask = Task { [weak self] in
            await self?.disableDynamicAddresses()
        }
    }

    private func disableDynamicAddresses() async {
        do {
            _ = try await transferModel.performAction()
            try Task.checkCancellation()

            try await walletModelDynamicAddressesProvider.disableDynamicAddresses()
            try Task.checkCancellation()

            analyticsLogger.logDynamicAddressesDisabled()

            await runOnMain { onFinish() }
        } catch is CancellationError {
            // Do nothing
        } catch let error as TransactionDispatcherResult.Error {
            await runOnMain { proceed(error: error) }
        } catch {
            AppLogger.error(error: error)
            await runOnMain { [alertPresenter] in
                alertPresenter.present(alert: error.alertBinder)
            }
        }
    }

    private func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .userCancelled, .transactionNotFound, .actionNotSupported:
            break
        case .informationRelevanceServiceError:
            alertPresenter.present(
                alert: sendAlertBuilder.makeFeeRetryAlert { [weak self] in
                    self?.transferModel.actualizeInformation()
                }
            )
        case .informationRelevanceServiceFeeWasIncreased:
            alertPresenter.present(
                alert: AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
            )
        case .sendTxError(_, let sendTxError):
            alertPresenter.present(alert: sendTxError.alertBinder)
        case .loadTransactionInfo(let error):
            alertPresenter.present(alert: error.alertBinder)
        case .demoAlert:
            alertPresenter.present(alert: AlertBuilder.makeDemoAlert())
        }
    }

    private func bind() {
        notificationManager.notificationPublisher
            .receiveOnMain()
            .handleEvents(receiveOutput: { [weak self] notifications in
                self?.logNotEnoughFeeNotice(notifications: notifications)
            })
            .assign(to: &$notificationInputs)

        transferModel.isNotificationButtonIsLoading
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        transferModel.actionInProcessing
            .receiveOnMain()
            .assign(to: &$isLoading)

        transferModel.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.tangemIconProvider.getMainButtonIcon() }
            .receiveOnMain()
            .assign(to: &$mainButtonIcon)

        transferModel.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.confirmTransactionPolicy.needsHoldToConfirm }
            .receiveOnMain()
            .assign(to: &$needsHoldToConfirm)
    }

    private func logNotEnoughFeeNotice(notifications: [NotificationViewInput]) {
        let hasInsufficientFeeNotification = notifications.contains { input in
            switch input.settings.event {
            case SendNotificationEvent.validationErrorEvent(.insufficientBalanceForFee(_)):
                return true
            default:
                return false
            }
        }

        guard hasInsufficientFeeNotification else { return }
        analyticsLogger.logTokenNoticeNotEnoughFee()
    }
}
