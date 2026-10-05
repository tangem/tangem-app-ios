//
//  TangemPayTransactionDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemVisa

/// Shows the transaction a payment push points at as a floating sheet, from wherever the user is.
final class TangemPayTransactionDeeplinkResponder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
}

// MARK: - IncomingActionResponder

extension TangemPayTransactionDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(.tangemPayTransaction(let deeplink)) = action else {
            return false
        }

        let payload = deeplink.payload

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == payload.customerWalletId }),
              let displayData = payload.displayData(using: TangemPayDisplayDataMapper())
        else {
            return false
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let accountProvider: (() async -> TangemPayAccount?)? = RTCUtil.isRootedDevice
                ? nil
                : { [weak self] in await self?.resolveAccount(for: userWalletModel) }

            let viewModel = TangemPayTransactionDetailsViewModel(
                displayData: displayData,
                origin: .push(payload),
                userWalletId: userWalletModel.userWalletId,
                customerId: payload.customerId,
                accountProvider: accountProvider,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }

        return true
    }
}

// MARK: - TangemPayTransactionDetailsRoutable

extension TangemPayTransactionDeeplinkResponder: TangemPayTransactionDetailsRoutable {
    func transactionDetailsDidRequestClose() {
        Task { @MainActor [floatingSheetPresenter] in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func transactionDetailsDidRequestDispute(dataCollector: EmailDataCollector, subject: VisaEmailSubject) {
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: subject).recipient,
            emailType: .visaFeedback(subject: subject)
        )

        Task { @MainActor [floatingSheetPresenter, mailPresenter] in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - Private

@MainActor
private extension TangemPayTransactionDeeplinkResponder {
    func resolveAccount(for userWalletModel: any UserWalletModel) async -> TangemPayAccount? {
        guard let accountModel = AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager) else {
            return nil
        }

        if let account = accountModel.state?.tangemPayAccount ?? accountModel.lastKnownTangemPayAccount {
            return account
        }

        let state = try? await accountModel.statePublisher
            .filter { $0.tangemPayAccount != nil }
            .timeout(.seconds(Constants.tangemPayStateTimeout), scheduler: DispatchQueue.main)
            .receiveOnMain()
            .async()

        return state?.tangemPayAccount
    }
}

// MARK: - Constants

private extension TangemPayTransactionDeeplinkResponder {
    enum Constants {
        static let tangemPayStateTimeout: TimeInterval = 10
    }
}
