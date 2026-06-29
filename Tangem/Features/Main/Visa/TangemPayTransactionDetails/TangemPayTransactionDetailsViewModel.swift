//
//  TangemPayTransactionDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemFoundation
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
    @Published private(set) var additionalInfo: TangemPayTransactionDetailsView.AdditionalInfo?

    @Published private(set) var displayModel: TangemPayTransactionDetailsDisplayModel?

    // MARK: - Dependencies

    private let origin: Origin
    private let userWalletId: UserWalletId
    private let customerId: String
    private weak var coordinator: TangemPayTransactionDetailsRoutable?

    struct DisplayData {
        let date: String
        let time: String
        let type: TransactionViewModel.TransactionType
        let status: TransactionViewModel.Status
        let isOutgoing: Bool
        let name: String
        let categoryName: String
        let amount: String
        let localAmount: String?
        let state: TangemPayTransactionDetailsStateView.TransactionState?
        let additionalInfo: TangemPayTransactionDetailsView.AdditionalInfo?
        let mainButtonAction: TangemPayTransactionDetailsViewModel.MainButtonAction
    }

    init(
        displayData: DisplayData,
        origin: Origin,
        userWalletId: UserWalletId,
        customerId: String,
        cardName: String? = nil,
        cardNumberEnd: String? = nil,
        coordinator: TangemPayTransactionDetailsRoutable
    ) {
        self.origin = origin
        self.userWalletId = userWalletId
        self.customerId = customerId
        self.coordinator = coordinator

        title = "\(displayData.date) \(AppConstants.dotSign) \(displayData.time)"
        iconData = TransactionViewIconViewData(
            type: displayData.type,
            status: displayData.status,
            isOutgoing: displayData.isOutgoing
        )
        name = displayData.name
        category = displayData.categoryName
        amount = TransactionViewAmountViewData(
            amount: displayData.amount,
            type: displayData.type,
            status: displayData.status,
            isOutgoing: displayData.isOutgoing,
            isFromYieldContract: false
        )
        localAmount = displayData.localAmount
        state = displayData.state
        additionalInfo = displayData.additionalInfo
        mainButtonAction = displayData.mainButtonAction

        displayModel = FeatureProvider.isAvailable(.tangemPaySpendRedesign)
            ? Self.makeDisplayModel(origin: origin, cardName: cardName, cardNumberEnd: cardNumberEnd)
            : nil
    }

    convenience init(
        transaction: TangemPayTransactionRecord,
        userWalletId: UserWalletId,
        customerId: String,
        cardName: String?,
        cardNumberEnd: String?,
        coordinator: TangemPayTransactionDetailsRoutable
    ) {
        self.init(
            displayData: transaction.displayData(using: TangemPayDisplayDataMapper()),
            origin: .history(transaction),
            userWalletId: userWalletId,
            customerId: customerId,
            cardName: cardName,
            cardNumberEnd: cardNumberEnd,
            coordinator: coordinator
        )
    }

    private static func makeDisplayModel(
        origin: Origin,
        cardName: String?,
        cardNumberEnd: String?
    ) -> TangemPayTransactionDetailsDisplayModel? {
        let mapper = TangemPayTransactionDetailsRedesignedMapper()
        switch origin {
        case .history(let transaction):
            return transaction.redesignedDisplayModel(using: mapper, cardName: cardName, cardNumberEnd: cardNumberEnd)
        case .push(let payload):
            return payload.redesignedDisplayModel(using: mapper)
        }
    }

    func userDidTapClose() {
        coordinator?.transactionDetailsDidRequestClose()
    }

    func userDidTapMainButton() {
        Analytics.log(.visaScreenSupportOnTransactionPopupClicked, contextParams: .userWallet(userWalletId))
        let subject: VisaEmailSubject = switch mainButtonAction {
        case .dispute: .dispute
        case .info: .default
        }

        let source: TangemPaySupportDataCollector.Source = switch origin {
        case .history(let transaction):
            .transactionDetails(transaction)
        case .push(let payload):
            .transactionDetailsPush(payload, mainButtonAction == .dispute ? .transaction : .receiveWithdraw)
        }

        let dataCollector = TangemPaySupportDataCollector(
            source: source,
            userWalletId: userWalletId.stringValue,
            customerId: customerId
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

    enum Origin {
        case history(TangemPayTransactionRecord)
        case push(TangemPayPushPayload)
    }
}
