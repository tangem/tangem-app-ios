//
//  WithdrawHubViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccounts
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils

final class WithdrawHubViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var alert: AlertBinder?
    @Published private(set) var isWithinPortfolioLoading = false

    @Published private(set) var recentTokens: WithdrawHubSectionState<WithdrawHubRecentTokenItem> = .loading
    @Published private(set) var recentAccounts: WithdrawHubSectionState<WithdrawHubRecentAccountItem> = .loading
    @Published private(set) var isSeeAllAccountsVisible = false
    @Published private(set) var bankTransferState: BankTransferState = .loading

    private let withdrawFlowResolver: TangemPayWithdrawFlowResolver
    private let tangemPayAccount: TangemPayAccount
    private let recentOperationsStore: TangemPayRecentOperationsStore
    private let recentRecipientsStore: TangemPayRecentRecipientsStore
    private let optionsStore: TangemPayOfframpOptionsStore
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    private var withdrawTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []
    private var recentOperationTargets: [String: TangemPayRecentOperationTarget] = [:]

    init(
        withdrawFlowResolver: TangemPayWithdrawFlowResolver,
        tangemPayAccount: TangemPayAccount,
        recentOperationsStore: TangemPayRecentOperationsStore,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        optionsStore: TangemPayOfframpOptionsStore,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.withdrawFlowResolver = withdrawFlowResolver
        self.tangemPayAccount = tangemPayAccount
        self.recentOperationsStore = recentOperationsStore
        self.recentRecipientsStore = recentRecipientsStore
        self.optionsStore = optionsStore
        self.analyticsLogger = analyticsLogger
        self.output = output

        bind()
        recentRecipientsStore.load()
        optionsStore.load()

        analyticsLogger.logBankTransferSheetOpened()
    }

    func onCloseTap() {
        output(.close)
    }

    // MARK: - Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .withinPortfolioTap:
            onWithinPortfolioTap()
        case .personalAccountTap:
            onPersonalAccountTap()
        case .businessAccountTap:
            onBusinessAccountTap()
        case .recentTokenTap(let id):
            onRecentTokenTap(id: id)
        case .recentAccountTap(let id):
            onRecentAccountTap(id: id)
        case .seeAllTap:
            onSeeAllTap()
        case .retryRecentAccountsTap:
            recentRecipientsStore.reload()
        }
    }

    private func onPersonalAccountTap() {
        analyticsLogger.logToPersonalAccountClicked()
        output(.startWizard(.newIndividual))
    }

    private func onBusinessAccountTap() {
        analyticsLogger.logToBusinessAccountClicked()
        output(.startWizard(.newBusiness))
    }

    private func onRecentTokenTap(id: String) {
        guard let target = recentOperationTargets[id] else {
            return
        }

        runWithdraw { withdrawFlowResolver in
            try await withdrawFlowResolver.resolve(repeating: target)
        }
    }

    private func onRecentAccountTap(id: String) {
        analyticsLogger.logSavedContactClicked()
        output(.startWizard(.saved(bankAccountId: id)))
    }

    private func onSeeAllTap() {
        analyticsLogger.logSavedContactsSeeAllClicked()
        output(.allRecipients)
    }

    private func onWithinPortfolioTap() {
        runWithdraw { withdrawFlowResolver in
            try await withdrawFlowResolver.resolve()
        }
    }

    private func runWithdraw(
        _ resolve: @escaping @MainActor (TangemPayWithdrawFlowResolver) async throws -> TangemPayWithdrawFlowResolver.Outcome
    ) {
        withdrawTask?.cancel()
        withdrawTask = runWithDelayedLoading(
            onLongRunning: { @MainActor [weak self] in
                self?.isWithinPortfolioLoading = true
            },
            onCancel: { [weak self] in
                guard let self else { return }

                Task { @MainActor in
                    self.isWithinPortfolioLoading = false
                }
            },
            operation: { @MainActor [weak self, withdrawFlowResolver] in
                defer { self?.isWithinPortfolioLoading = false }

                do {
                    let outcome = try await resolve(withdrawFlowResolver)

                    guard !Task.isCancelled, let self else { return }

                    handle(outcome)
                } catch is CancellationError {
                    // Do nothing
                } catch {
                    self?.alert = error.alertBinder
                }
            }
        )
    }

    private func bind() {
        recentOperationsStore
            .operationsPublisher(customerWalletId: tangemPayAccount.userWalletId.stringValue)
            .receiveOnMain()
            .sink { [weak self] operations in
                self?.updateRecentTokens(with: operations)
            }
            .store(in: &bag)

        recentRecipientsStore.statePublisher
            .receiveOnMain()
            .map { state -> WithdrawHubSectionState<WithdrawHubRecentAccountItem> in
                switch state {
                case .loading:
                    .loading
                case .loaded(let bankAccounts):
                    .loaded(bankAccounts.prefix(Constants.maxRecentAccounts).map(Self.makeRecentAccountItem(from:)))
                case .failed:
                    .failed
                }
            }
            .assign(to: &$recentAccounts)

        recentRecipientsStore.statePublisher
            .receiveOnMain()
            .map { $0.recipients.count > Constants.maxRecentAccounts }
            .assign(to: &$isSeeAllAccountsVisible)

        optionsStore
            .statePublisher
            .receiveOnMain()
            .map { state -> BankTransferState in
                switch state {
                case .loading:
                    .loading
                case .loaded(let options):
                    options.hasAvailableTokens && options.rails.isNotEmpty ? .available : .unavailable
                }
            }
            .assign(to: &$bankTransferState)
    }

    private func updateRecentTokens(with operations: [TangemPayRecentOperation]) {
        let eligibleTokenItems = eligiblePaymentTokenItems()

        let targets = operations
            .compactMap { operation in
                resolveTarget(for: operation, eligibleTokenItems: eligibleTokenItems).map { (operation.repeatKey, $0) }
            }
            .prefix(Constants.maxRecentTokens)

        recentOperationTargets = Dictionary(Array(targets), uniquingKeysWith: { first, _ in first })
        recentTokens = .loaded(targets.compactMap { id, target in
            Self.makeRecentTokenItem(id: id, target: target)
        })
    }

    private func eligiblePaymentTokenItems() -> [TokenItem] {
        TangemPayAccountTokensResolver()
            .resolve(networks: tangemPayAccount.networks)
            .filter(\.isWithdrawEligible)
            .map(\.tokenItem)
    }

    private func resolveTarget(
        for operation: TangemPayRecentOperation,
        eligibleTokenItems: [TokenItem]
    ) -> TangemPayRecentOperationTarget? {
        let paymentTokenItem = operation.paymentAccountSide.tokenItem
        let counterpart = operation.counterpartSide

        guard eligibleTokenItems.contains(paymentTokenItem),
              let userWalletModel = userWalletRepository.models.first(where: {
                  $0.userWalletId.stringValue == counterpart.userWalletId
              })
        else {
            return nil
        }

        let walletModelId = WalletModelId(tokenItem: counterpart.tokenItem)
        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let walletModel = walletModels.first(where: { $0.id == walletModelId }), walletModel.account != nil else {
            return nil
        }

        return TangemPayRecentOperationTarget(
            paymentAccountTokenItem: paymentTokenItem,
            receiveUserWalletInfo: userWalletModel.userWalletInfo,
            receiveWalletModel: walletModel
        )
    }

    private static func makeRecentTokenItem(
        id: String,
        target: TangemPayRecentOperationTarget
    ) -> WithdrawHubRecentTokenItem? {
        let walletModel = target.receiveWalletModel

        guard let account = walletModel.account else {
            return nil
        }

        return WithdrawHubRecentTokenItem(
            id: id,
            tokenIconInfo: TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom),
            name: walletModel.tokenItem.name,
            accountIcon: AccountModelUtils.UI.iconViewData(accountModel: account),
            accountName: account.name
        )
    }

    private static func makeRecentAccountItem(
        from bankAccount: TangemPayBankAccountResponse
    ) -> WithdrawHubRecentAccountItem {
        let name = TangemPayRecipientNameFormatter.name(for: bankAccount, style: .abbreviated)

        return WithdrawHubRecentAccountItem(
            id: bankAccount.id,
            monogram: TangemPayRecipientNameFormatter.monogram(for: name),
            name: name,
            accountNumber: bankAccount.details.accountNumber
        )
    }

    private func handle(_ outcome: TangemPayWithdrawFlowResolver.Outcome) {
        switch outcome {
        case .swap(let swapParameters):
            output(.withdraw(swapParameters))

        case .pendingWithdrawOrder:
            output(.withdrawInProgress)

        case .unavailable:
            output(.noDepositAddress)

        case .restricted(let restriction):
            alert = TokenActionAvailabilityAlertBuilder().alert(for: restriction)
        }
    }
}

// MARK: - Constants

private extension WithdrawHubViewModel {
    enum Constants {
        static let maxRecentAccounts = 3
        static let maxRecentTokens = 3
    }
}

// MARK: - BankTransferState

extension WithdrawHubViewModel {
    enum BankTransferState {
        case loading
        case available
        case unavailable

        var isEnabled: Bool {
            self == .available
        }
    }
}

// MARK: - ViewAction

extension WithdrawHubViewModel {
    enum ViewAction: Equatable {
        case withinPortfolioTap
        case personalAccountTap
        case businessAccountTap
        case recentTokenTap(id: String)
        case recentAccountTap(id: String)
        case seeAllTap
        case retryRecentAccountsTap
    }
}

// MARK: - Output

extension WithdrawHubViewModel {
    enum Output {
        case withdraw(PredefinedSwapParameters)
        case withdrawInProgress
        case noDepositAddress
        case allRecipients
        case startWizard(TangemPayOfframpRecipient)
        case close
    }
}
