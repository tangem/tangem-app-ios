//
//  TangemPayMoneyAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
final class TangemPayMoneyAccountViewModel: ObservableObject {
    @Published private(set) var stateModel: TangemPayMoneyAccountStateModel
    @Published private(set) var menuSections: [[TangemPayMoneyAccountMenuItem]] = []

    let refreshScrollState = RefreshScrollViewStateObject(refreshable: {})

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager

    private let userWalletModel: any UserWalletModel
    private let output: (Output) -> Void

    init(
        userWalletModel: any UserWalletModel,
        output: @escaping (Output) -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.output = output

        // [REDACTED_TODO_COMMENT]
        stateModel = TangemPayMoneyAccountStateModel(
            balance: .loaded("$0,00"),
            transactionHistory: .loaded([])
        )

        // [REDACTED_TODO_COMMENT]
        menuSections = makeMenuSections()
    }

    func handleAction(_ action: TangemPayMoneyAccountAction) {
        switch action {
        case .topup:
            output(.topup)

        case .withdraw:
            output(.withdraw)

        case .selectMenuItem(let item):
            handleMenuItem(item)

        case .reloadTransactionHistory:
            // [REDACTED_TODO_COMMENT]
            break

        case .openTransactionDetails:
            // [REDACTED_TODO_COMMENT]
            break

        case .openExplorer:
            // [REDACTED_TODO_COMMENT]
            break

        case .openYieldMode:
            break
        }
    }
}

// MARK: - Output

extension TangemPayMoneyAccountViewModel {
    enum Output {
        case topup
        case withdraw
    }
}

// MARK: - Menu

private extension TangemPayMoneyAccountViewModel {
    func makeMenuSections() -> [[TangemPayMoneyAccountMenuItem]] {
        [
            // [REDACTED_TODO_COMMENT]
            [.currentPlan(planName: "Basic"), .termsAndFees, .support],
            [.closeAccount],
        ]
    }

    func handleMenuItem(_ item: TangemPayMoneyAccountMenuItem) {
        switch item {
        case .currentPlan:
            // [REDACTED_TODO_COMMENT]
            break

        case .termsAndFees:
            safariManager.openURL(AppConstants.tangemPayTermsOfServiceURL)

        case .support:
            contactSupport(subject: .usdAccountGeneralHelp)

        case .closeAccount:
            contactSupport(subject: .usdAccountCloseAccount)
        }
    }

    func contactSupport(subject: VisaEmailSubject) {
        // [REDACTED_TODO_COMMENT]
        let dataCollector = TangemPayMoneyAccountSupportDataCollector(customerId: nil, accountId: nil)
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: subject).recipient,
            emailType: .visaFeedback(subject: subject)
        )

        mailPresenter.present(viewModel: mailViewModel)
    }
}
