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

    private let withdrawFlowResolver: TangemPayWithdrawFlowResolver
    private let recentRecipientsStore: TangemPayRecentRecipientsStore
    private let output: (Output) -> Void

    private var withinPortfolioTask: Task<Void, Error>?

    init(
        withdrawFlowResolver: TangemPayWithdrawFlowResolver,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        output: @escaping (Output) -> Void
    ) {
        self.withdrawFlowResolver = withdrawFlowResolver
        self.recentRecipientsStore = recentRecipientsStore
        self.output = output

        bind()
        recentRecipientsStore.load()
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
        // [REDACTED_TODO_COMMENT]
    }

    private func onBusinessAccountTap() {
        // [REDACTED_TODO_COMMENT]
    }

    private func onRecentTokenTap(id: String) {
        // [REDACTED_TODO_COMMENT]
    }

    private func onRecentAccountTap(id: String) {
        recentRecipientsStore.recordSelection(id: id)

        // [REDACTED_TODO_COMMENT]
    }

    private func onSeeAllTap() {
        // [REDACTED_TODO_COMMENT]
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
    }

    private static func makeRecentAccountItem(
        from bankAccount: TangemPayBankAccountResponse
    ) -> WithdrawHubRecentAccountItem {
        let name = makeName(for: bankAccount)

        return WithdrawHubRecentAccountItem(
            id: bankAccount.id,
            monogram: name.prefix(1).uppercased(),
            name: name,
            accountNumber: bankAccount.details.accountNumber
        )
    }

    private static func makeName(for bankAccount: TangemPayBankAccountResponse) -> String {
        let beneficiary = bankAccount.details.beneficiary

        switch beneficiary.type {
        case .business:
            if let businessName = beneficiary.businessName?.nilIfEmpty {
                return businessName
            }

        case .individual, .none:
            if let firstName = beneficiary.firstName?.nilIfEmpty {
                guard let lastNameInitial = beneficiary.lastName?.nilIfEmpty?.prefix(1) else {
                    return firstName
                }

                return "\(firstName) \(lastNameInitial)."
            }
        }

        return bankAccount.displayName?.nilIfEmpty ?? bankAccount.details.accountNumber
    }

    private func handle(_ outcome: TangemPayWithdrawFlowResolver.Outcome) {
        switch outcome {
        case .swap(let swapParameters):
            output(.withdrawNote(swapParameters))

        case .pendingWithdrawOrder:
            output(.withdrawInProgress)

        case .unavailable:
            output(.noDepositAddress)

        case .restricted(let restriction):
            alert = TokenActionAvailabilityAlertBuilder().alert(for: restriction)
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
        case withdrawNote(PredefinedSwapParameters)
        case withdrawInProgress
        case noDepositAddress
        case close
    }
}
