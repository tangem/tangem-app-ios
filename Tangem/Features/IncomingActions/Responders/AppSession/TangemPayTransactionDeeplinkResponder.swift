//
//  TangemPayTransactionDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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

        let viewModel = TangemPayTransactionDetailsViewModel(
            displayData: displayData,
            origin: .push(payload),
            userWalletId: userWalletModel.userWalletId,
            customerId: payload.customerId,
            coordinator: self
        )

        Task { @MainActor [floatingSheetPresenter] in
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
