//
//  WithdrawHubViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils

final class WithdrawHubViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published private(set) var isWithinPortfolioLoading = false

    // [REDACTED_TODO_COMMENT]
    @Published private(set) var recentTokens: WithdrawHubSectionState<WithdrawHubRecentTokenItem> = .loaded([])
    @Published private(set) var recentAccounts: WithdrawHubSectionState<WithdrawHubRecentAccountItem> = .loading
    @Published private(set) var bankTransferState: BankTransferState = .loading

    private let withdrawFlowResolver: TangemPayWithdrawFlowResolver
    private let recentRecipientsStore: TangemPayRecentRecipientsStore
    private let optionsStore: TangemPayOfframpOptionsStore
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    private var withinPortfolioTask: Task<Void, Error>?

    init(
        withdrawFlowResolver: TangemPayWithdrawFlowResolver,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        optionsStore: TangemPayOfframpOptionsStore,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.withdrawFlowResolver = withdrawFlowResolver
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
        // [REDACTED_TODO_COMMENT]
    }

    private func onRecentAccountTap(id: String) {
        analyticsLogger.logSavedContactClicked()
        recentRecipientsStore.recordSelection(id: id)
        output(.startWizard(.saved(bankAccountId: id)))
    }

    private func onSeeAllTap() {
        analyticsLogger.logSavedContactsSeeAllClicked()
        output(.allRecipients)
    }

    private func onWithinPortfolioTap() {
        withinPortfolioTask?.cancel()
        withinPortfolioTask = runWithDelayedLoading(
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
                    let outcome = try await withdrawFlowResolver.resolve()

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
        recentRecipientsStore.recentsPublisher
            .receiveOnMain()
            .map { state -> WithdrawHubSectionState<WithdrawHubRecentAccountItem> in
                switch state {
                case .loading:
                    .loading
                case .loaded(let bankAccounts):
                    .loaded(bankAccounts.map(Self.makeRecentAccountItem(from:)))
                }
            }
            .assign(to: &$recentAccounts)

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
