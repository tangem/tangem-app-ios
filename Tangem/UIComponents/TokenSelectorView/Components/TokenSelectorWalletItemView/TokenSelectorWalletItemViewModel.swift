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

    @Published private(set) var isOpen: Bool = true
    @Published private(set) var contentVisibility: TokenSelectorViewModel.ContentVisibility?
    @Published private(set) var isFilteredOut: Bool = false

    init(
        walletId: UserWalletId,
        walletName: String,
        viewType: ViewType
    ) {
        self.walletId = walletId
        self.walletName = walletName
        self.viewType = viewType

        contentVisibility = .empty

        bind()
    }

    func toggleIsOpen() {
        withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
    }

    func update(isOpen: Bool) {
        self.isOpen = isOpen
    }

    func update(isFilteredOut: Bool) {
        self.isFilteredOut = isFilteredOut
    }

    private func bind() {
        viewType.itemsCount
            .removeDuplicates()
            .map { $0 == 0 ? .empty : .visible(itemsCount: $0) }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }
}

extension TokenSelectorWalletItemViewModel {
    enum ViewType {
        case wallet(TokenSelectorAccountViewModel)
        case accounts([TokenSelectorAccountViewModel])
    }
}

extension TokenSelectorWalletItemViewModel.ViewType {
    var itemsCount: AnyPublisher<Int, Never> {
        switch self {
        case .wallet(let wallet):
            return wallet.itemsCountPublisher
        case .accounts(let accounts):
            return accounts
                .map { $0.itemsCountPublisher }
                .combineLatest()
                .map { $0.sum() }
                .eraseToAnyPublisher()
        }
    }
}
