//
//  RecentRecipientsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

final class RecentRecipientsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isSearchActive = false
    @Published private(set) var recipients: [RecentRecipientItem] = []

    private let recentRecipientsStore: TangemPayRecentRecipientsStore
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (String) -> Void

    init(
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (String) -> Void
    ) {
        self.recentRecipientsStore = recentRecipientsStore
        self.analyticsLogger = analyticsLogger
        self.output = output

        bind()

        if recentRecipientsStore.recipients.isEmpty {
            recentRecipientsStore.load()
        }

        analyticsLogger.logSavedContactsScreenOpened()
    }

    func onRecipientTap(id: String) {
        analyticsLogger.logSavedContactOnContactsScreenClicked()
        output(id)
    }

    func searchActiveDidChange(to isActive: Bool) {
        guard isActive else { return }

        analyticsLogger.logSearchBarClicked()
    }

    private func bind() {
        Publishers.CombineLatest(recentRecipientsStore.recipientsPublisher, $searchText)
            .map { bankAccounts, searchText in
                Self.makeItems(from: bankAccounts, searchText: searchText)
            }
            .receiveOnMain()
            .assign(to: &$recipients)
    }

    private static func makeItems(
        from bankAccounts: [TangemPayBankAccountResponse],
        searchText: String
    ) -> [RecentRecipientItem] {
        let query = searchText.trimmed()

        return bankAccounts
            .map(makeItem(from:))
            .filter { query.isEmpty || $0.matches(query: query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func makeItem(from bankAccount: TangemPayBankAccountResponse) -> RecentRecipientItem {
        let name = TangemPayRecipientNameFormatter.name(for: bankAccount, style: .full)

        return RecentRecipientItem(
            id: bankAccount.id,
            monogram: TangemPayRecipientNameFormatter.monogram(for: name),
            name: name,
            accountNumber: bankAccount.details.accountNumber
        )
    }
}

// MARK: - Matching

private extension RecentRecipientItem {
    func matches(query: String) -> Bool {
        name.caseInsensitiveContains(query) || accountNumber.caseInsensitiveContains(query)
    }
}
