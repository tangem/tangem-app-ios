//
//  UserWalletSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemFoundation
import TangemLocalization

@MainActor
final class UserWalletSelectorViewModel: ObservableObject {
    let title: String = Localization.commonChooseWallet

    @Published private(set) var items: [UserWalletSelectorItem] = []
    @Published private(set) var isBalanceMasked: Bool
    @Published var unavailableReason: SelectorUnavailableReason?

    private let userWalletModels: [any UserWalletModel]
    private let availabilityProvider: any UserWalletSelectorAvailabilityProvider
    private let onSelect: (UserWalletId) -> Void
    private let itemsStore = UserWalletSelectorItemsStore()

    private var bag = Set<AnyCancellable>()

    init(
        userWalletsProvider: any UserWalletSelectorUserWalletsProvider,
        availabilityProvider: any UserWalletSelectorAvailabilityProvider = .lockState(),
        onSelect: @escaping (UserWalletId) -> Void
    ) {
        userWalletModels = userWalletsProvider.userWalletModels
        self.availabilityProvider = availabilityProvider
        self.onSelect = onSelect
        isBalanceMasked = SensitiveTextVisibilityViewModel.shared.isHidden

        bind()
        rebuildItems()
    }

    func select(_ item: UserWalletSelectorItem) {
        guard let userWalletModel = userWalletModels.first(where: { $0.userWalletId == item.id }) else {
            return
        }

        switch availabilityProvider.availability(of: userWalletModel) {
        case .available:
            onSelect(userWalletModel.userWalletId)
        case .locked:
            break
        case .unavailable(let reason):
            unavailableReason = reason
        }
    }
}

// MARK: - Private

private extension UserWalletSelectorViewModel {
    func bind() {
        itemsStore.onChange = { [weak self] in
            self?.rebuildItems()
        }
        itemsStore.track(userWalletModels)

        SensitiveTextVisibilityViewModel.shared.$isHidden
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isHidden in
                viewModel.isBalanceMasked = isHidden
            }
            .store(in: &bag)
    }

    func rebuildItems() {
        items = userWalletModels.map { userWalletModel in
            itemsStore.item(for: userWalletModel, availability: availabilityProvider.availability(of: userWalletModel))
        }
    }
}
