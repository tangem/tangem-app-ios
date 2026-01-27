//
//  TangemPayTransactionDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemLocalization

final class TangemPayTransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published private(set) var title: String
    @Published private(set) var iconData: TransactionViewIconViewData
    @Published private(set) var name: String
    @Published private(set) var category: String
    @Published private(set) var amount: TransactionViewAmountViewData
    @Published private(set) var localAmount: String?

    @Published private(set) var state: TangemPayTransactionDetailsStateView.TransactionState?
    @Published private(set) var mainButtonAction: MainButtonAction
    @Published private(set) var bottomInfo: String?

    // MARK: - Dependencies

    private let transaction: TangemPayTransactionRecord
    private let userWalletId: String
    private weak var coordinator: TangemPayTransactionDetailsRoutable?

    init(
        transaction: TangemPayTransactionRecord,
        userWalletId: String,
        coordinator: TangemPayTransactionDetailsRoutable
    ) {
        self.transaction = transaction
        self.userWalletId = userWalletId
        self.coordinator = coordinator

        let mapper = TangemPayTransactionRecordMapper(transaction: transaction)

        title = "\(mapper.date()) \(AppConstants.dotSign) \(mapper.time())"
        iconData = TransactionViewIconViewData(
            type: mapper.type(),
            status: mapper.status(),
            isOutgoing: mapper.isOutgoing()
        )
        name = mapper.name()
        category = mapper.categoryName()
        amount = TransactionViewAmountViewData(
            amount: mapper.amount(),
            type: mapper.type(),
            status: mapper.status(),
            isOutgoing: mapper.isOutgoing(),
            isFromYieldContract: false
        )
        localAmount = mapper.localAmount()
        state = mapper.state()
        bottomInfo = mapper.additionalInfo()
        mainButtonAction = mapper.mainButtonAction()
    }

    func userDidTapClose() {
        coordinator?.transactionDetailsDidRequestClose()
    }

    func userDidTapMainButton() {
        Analytics.log(.visaScreenSupportOnTransactionPopupClicked)
        let subject: VisaEmailSubject = switch mainButtonAction {
        case .dispute: .dispute
        case .info: .default
        }

        let dataCollector = TangemPaySupportDataCollector(
            source: .transactionDetails(transaction),
            userWalletId: userWalletId
        )

        coordinator?.transactionDetailsDidRequestDispute(dataCollector: dataCollector, subject: subject)
    }
}

extension TangemPayTransactionDetailsViewModel {
    enum MainButtonAction {
        case dispute
        case info

        var title: String {
            switch self {
            case .dispute, .info:
                Localization.tangemPayGetHelp
            }
        }
    }
}
