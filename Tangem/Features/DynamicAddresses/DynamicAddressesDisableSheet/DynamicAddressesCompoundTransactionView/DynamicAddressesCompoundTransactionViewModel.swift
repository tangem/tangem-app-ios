//
//  DynamicAddressesCompoundTransactionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

final class DynamicAddressesCompoundTransactionViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let feeCompactViewModel: FeeCompactViewModel

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?

    private let transferModel: TransferModel
    private let notificationManager: SendNotificationManager
    private let sendAlertBuilder: SendAlertBuilder = CommonSendAlertBuilder()
    private let onFinish: () -> Void

    init(
        transferModel: TransferModel,
        notificationManager: SendNotificationManager,
        onFinish: @escaping () -> Void
    ) {
        self.transferModel = transferModel
        self.notificationManager = notificationManager
        self.onFinish = onFinish

        feeCompactViewModel = FeeCompactViewModel(showsLeadingIcon: false)
        feeCompactViewModel.bind(input: transferModel)

        bind()
        transferModel.updateFees()
    }

    func confirm() {
        Task {
            do {
                _ = try await transferModel.performAction()
                // [REDACTED_TODO_COMMENT]
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
            .assign(to: &$notificationInputs)

        transferModel.isNotificationButtonIsLoading
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        transferModel.actionInProcessing
            .receiveOnMain()
            .assign(to: &$isLoading)
    }
}
