//
//  TangemPayRecentRecipientsStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPay
import TangemVisa

final class TangemPayRecentRecipientsStore {
    var statePublisher: some Publisher<State, Never> {
        stateSubject
    }

    var recipientsPublisher: some Publisher<[TangemPayBankAccountResponse], Never> {
        stateSubject.map(\.recipients)
    }

    var recipients: [TangemPayBankAccountResponse] {
        stateSubject.value.recipients
    }

    private let repository: any TangemPayBankAccountsRepository
    private let stateSubject = CurrentValueSubject<State, Never>(.loading)

    private var loadTask: Task<Void, Never>?

    init(repository: any TangemPayBankAccountsRepository) {
        self.repository = repository
    }

    func load() {
        guard loadTask == nil else { return }

        startLoad()
    }

    func reload() {
        loadTask?.cancel()

        if case .failed = stateSubject.value {
            stateSubject.send(.loading)
        }

        startLoad()
    }

    private func startLoad() {
        loadTask = Task { @MainActor [weak self, repository] in
            do {
                let bankAccounts = try await repository.bankAccounts()
                self?.stateSubject.send(.loaded(bankAccounts))
            } catch {
                VisaLogger.error("Failed to load Tangem Pay bank accounts", error: error)
                self?.handleLoadFailure()
            }
        }
    }

    private func handleLoadFailure() {
        guard case .loading = stateSubject.value else {
            return
        }

        stateSubject.send(.failed)
    }
}

// MARK: - State

extension TangemPayRecentRecipientsStore {
    enum State {
        case loading
        case loaded([TangemPayBankAccountResponse])
        case failed

        var recipients: [TangemPayBankAccountResponse] {
            switch self {
            case .loading, .failed:
                []
            case .loaded(let bankAccounts):
                bankAccounts
            }
        }
    }
}
