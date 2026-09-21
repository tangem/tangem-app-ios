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
    var recentsPublisher: some Publisher<State, Never> {
        Publishers.CombineLatest(stateSubject, recentIdsSubject)
            .map { state, recentIds -> State in
                switch state {
                case .loading:
                    .loading
                case .loaded(let bankAccounts):
                    .loaded(Self.recents(from: bankAccounts, recentIds: recentIds))
                }
            }
    }

    var recipientsPublisher: some Publisher<[TangemPayBankAccountResponse], Never> {
        stateSubject.map(\.recipients)
    }

    var recipients: [TangemPayBankAccountResponse] {
        stateSubject.value.recipients
    }

    private let repository: any TangemPayBankAccountsRepository
    private let cacheStorage: any TangemPayRecentRecipientsCacheStorage
    private let customerWalletId: String

    private let stateSubject = CurrentValueSubject<State, Never>(.loading)
    private let recentIdsSubject: CurrentValueSubject<[String], Never>

    private var loadTask: Task<Void, Never>?

    init(
        repository: any TangemPayBankAccountsRepository,
        cacheStorage: any TangemPayRecentRecipientsCacheStorage,
        customerWalletId: String
    ) {
        self.repository = repository
        self.cacheStorage = cacheStorage
        self.customerWalletId = customerWalletId

        recentIdsSubject = CurrentValueSubject(cacheStorage.recentRecipientIds(customerWalletId: customerWalletId))
    }

    func load() {
        guard loadTask == nil else { return }

        startLoad()
    }

    func reload() {
        loadTask?.cancel()

        startLoad()
    }

    func recordSelection(id: String) {
        cacheStorage.recordRecipientUsage(id: id, customerWalletId: customerWalletId)
        recentIdsSubject.send(cacheStorage.recentRecipientIds(customerWalletId: customerWalletId))
    }

    func recordNewRecipient(id: String) {
        recordSelection(id: id)
        reload()
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

        stateSubject.send(.loaded([]))
    }
}

// MARK: - State

extension TangemPayRecentRecipientsStore {
    enum State {
        case loading
        case loaded([TangemPayBankAccountResponse])

        var recipients: [TangemPayBankAccountResponse] {
            switch self {
            case .loading:
                []
            case .loaded(let bankAccounts):
                bankAccounts
            }
        }
    }
}

// MARK: - Helpers

private extension TangemPayRecentRecipientsStore {
    static func recents(
        from bankAccounts: [TangemPayBankAccountResponse],
        recentIds: [String]
    ) -> [TangemPayBankAccountResponse] {
        let bankAccountsById = Dictionary(
            bankAccounts.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return recentIds.compactMap { bankAccountsById[$0] }
    }
}
