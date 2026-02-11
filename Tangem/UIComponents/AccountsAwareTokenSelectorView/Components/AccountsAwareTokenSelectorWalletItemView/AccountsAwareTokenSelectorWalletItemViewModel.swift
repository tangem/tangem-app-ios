//
//  AccountsAwareTokenSelectorWalletItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts

final class AccountsAwareTokenSelectorWalletItemViewModel: ObservableObject, Identifiable {
    @Published private(set) var isOpen: Bool = true

    @Published private(set) var viewType: ViewType
    @Published private(set) var contentVisibility: AccountsAwareTokenSelectorViewModel.ContentVisibility?

    init(
        isOpen: Bool = true,
        viewType: ViewType,
        viewTypePublisher: AnyPublisher<ViewType, Never>
    ) {
        self.isOpen = isOpen
        self.viewType = viewType

        viewTypePublisher.receiveOnMain().assign(to: &$viewType)

        bind()
    }

    func toggleIsOpen() {
        withAnimation(.easeInOut(duration: 0.4)) { isOpen.toggle() }
    }

    func update(isOpen: Bool) {
        self.isOpen = isOpen
    }

    private func bind() {
        $viewType
            .flatMapLatest { $0.itemsCount }
            .removeDuplicates()
            .map { $0 == .zero ? .empty : .visible }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }
}

extension AccountsAwareTokenSelectorWalletItemViewModel {
    enum ViewType {
        case wallet(AccountsAwareTokenSelectorAccountViewModel)
        case accounts(walletName: String, accounts: [AccountsAwareTokenSelectorAccountViewModel])
    }
}

extension AccountsAwareTokenSelectorWalletItemViewModel.ViewType {
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
