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
import TangemPay

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
    private let accountProvider: (() async -> TangemPayAccount?)?
    private let mapper = TangemPayTransactionDetailsMapper()
    private var cardLoadTask: Task<Void, Never>?
    private var cashbackLoadTask: Task<Void, Never>?
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
        accountProvider: (() async -> TangemPayAccount?)?,
        coordinator: TangemPayTransactionDetailsRoutable
    ) {
        self.origin = origin
        self.userWalletId = userWalletId
        self.customerId = customerId
        self.accountProvider = accountProvider
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
            value: displayData.amount,
            type: displayData.type,
            status: displayData.status,
            isOutgoing: displayData.isOutgoing,
            isFromYieldContract: false
        )
        localAmount = displayData.localAmount
        state = displayData.state
        additionalInfo = displayData.additionalInfo
        mainButtonAction = displayData.mainButtonAction

        displayModel = makeDisplayModel(origin: origin)

        startCardLoad()
        startCashbackLoad()
    }

    convenience init(
        transaction: TangemPayTransactionRecord,
        userWalletId: UserWalletId,
        customerId: String,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayTransactionDetailsRoutable
    ) {
        self.init(
            displayData: transaction.displayData(using: TangemPayDisplayDataMapper()),
            origin: .history(transaction),
            userWalletId: userWalletId,
            customerId: customerId,
            accountProvider: { tangemPayAccount },
            coordinator: coordinator
        )
    }

    private func makeDisplayModel(origin: Origin) -> TangemPayTransactionDetailsDisplayModel? {
        switch origin {
        case .history(let transaction):
            return transaction.displayModel(using: mapper)
        case .push(let payload):
            return payload.displayModel(using: mapper)
        }
    }

    func userDidTapClose() {
        coordinator?.transactionDetailsDidRequestClose()
    }

    func userDidTapMainButton() {
        Analytics.log(.visaScreenSupportOnTransactionPopupClicked, contextParams: .userWallet(userWalletId))
        let subject: VisaEmailSubject = switch mainButtonAction {
        case .dispute: .payment
        case .info: .depositWithdrawal
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

    func retryCardLoad() {
        startCardLoad()
    }

    func retryCashbackLoad() {
        startCashbackLoad()
    }

    private func startCardLoad() {
        guard let transactionId = merchantTransactionId else {
            return
        }

        cardLoadTask?.cancel()
        displayModel?.cardRow = .loading
        cardLoadTask = runTask(in: self) { viewModel in
            await viewModel.loadCard(transactionId: transactionId)
        }
    }

    private func startCashbackLoad() {
        guard let transactionId = merchantTransactionId else {
            return
        }

        cashbackLoadTask?.cancel()
        displayModel?.cashbackRow = .loading
        cashbackLoadTask = runTask(in: self) { viewModel in
            await viewModel.loadCashback(transactionId: transactionId)
        }
    }

    private var merchantTransactionId: String? {
        guard accountProvider != nil else {
            return nil
        }

        switch origin {
        case .history(let transaction):
            guard case .merchant = transaction.record.displayRecord else {
                return nil
            }
            return transaction.id
        case .push(let payload):
            return payload.spendTransactionId
        }
    }

    @MainActor
    private func resolveAccount() async -> TangemPayAccount? {
        guard let accountProvider else {
            return nil
        }

        return await accountProvider()
    }

    @MainActor
    private func loadCard(transactionId: String) async {
        guard let account = await resolveAccount() else {
            displayModel?.cardRow = .failed
            return
        }

        do {
            let response = try await account.getTransaction(transactionId: transactionId)

            if case .push = origin {
                var refreshedModel = response.displayModel(using: mapper)
                refreshedModel.cashbackRow = displayModel?.cashbackRow
                displayModel = refreshedModel
            }

            if case .merchant(let merchant) = response.record.displayRecord, let cardNumberEnd = merchant.cardNumberEnd {
                displayModel?.cardRow = .loaded(cardNumberEnd: cardNumberEnd, cardName: merchant.cardDisplayName)
            } else {
                displayModel?.cardRow = .failed
            }
        } catch {
            displayModel?.cardRow = .failed
        }
    }

    @MainActor
    private func loadCashback(transactionId: String) async {
        guard let account = await resolveAccount() else {
            displayModel?.cashbackRow = .failed
            return
        }

        do {
            let response = try await account.getCashbackTransactionDetails(transactionId: transactionId)
            displayModel?.cashbackRow = mapper.map(cashback: TangemPayTransactionCashback(response))
        } catch {
            displayModel?.cashbackRow = .failed
            Analytics.log(.visaCashbackLoadingErrorShowed, contextParams: .userWallet(userWalletId))
        }
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
