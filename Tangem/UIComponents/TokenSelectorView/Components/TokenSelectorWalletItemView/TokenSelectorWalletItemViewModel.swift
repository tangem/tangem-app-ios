//
//  TokenSelectorWalletItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts
import TangemFoundation

final class TokenSelectorWalletItemViewModel: ObservableObject, Identifiable {
    let walletId: UserWalletId
    let walletName: String

    let viewType: ViewType
    var hideWalletHeader: Bool = false

    @Published private(set) var isOpen: Bool = true
    @Published private(set) var contentVisibility: TokenSelectorViewModel.ContentVisibility?
    @Published var isFilteredOut: Bool = false

    private let onOpenStateChange: ((Bool) -> Void)?

    init(
        walletId: UserWalletId,
        walletName: String,
        isOpen: Bool = true,
        viewType: ViewType,
        onOpenStateChange: ((Bool) -> Void)? = nil
    ) {
        self.walletId = walletId
        self.walletName = walletName
        self.isOpen = isOpen
        self.viewType = viewType
        self.onOpenStateChange = onOpenStateChange

        // Set initial contentVisibility synchronously so it's available before any view renders
        contentVisibility = viewType.initialContentVisibility

        bind()
    }

    func toggleIsOpen() {
        withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
        onOpenStateChange?(isOpen)
    }

    func update(isOpen: Bool) {
        self.isOpen = isOpen
    }

    private func bind() {
        viewType.itemsCount
            .removeDuplicates()
            .map { $0 == .zero ? .empty : .visible(itemsCount: $0) }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }
}

extension TokenSelectorWalletItemViewModel {
    enum ViewType {
        case wallet(TokenSelectorAccountViewModel)
        case accounts(walletName: String, accounts: [TokenSelectorAccountViewModel])
    }
}

extension TokenSelectorWalletItemViewModel.ViewType {
    var initialContentVisibility: TokenSelectorViewModel.ContentVisibility {
        let count: Int
        switch self {
        case .wallet(let account):
            count = account.items.count
        case .accounts(_, let accounts):
            count = accounts.reduce(0) { $0 + $1.items.count }
        }
        return count == 0 ? .empty : .visible(itemsCount: count)
    }

    var itemsCount: AnyPublisher<Int, Never> {
        switch self {
        case .wallet(let wallet):
            return wallet.itemsCountPublisher
        case .accounts(_, let accounts):
            return accounts
                .map { $0.itemsCountPublisher }
                .combineLatest()
                .map { $0.sum() }
                .eraseToAnyPublisher()
        }
    }
}
