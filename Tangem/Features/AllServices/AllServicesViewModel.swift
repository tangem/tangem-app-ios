//
//  AllServicesViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class AllServicesViewModel: ObservableObject {
    @Published private(set) var actions: [AllServicesItem] = []

    // [REDACTED_TODO_COMMENT]
    let title = "All services"
    let subtitle = "Everything available to you in one place.\nAdd what you need, when you need it."

    private let layout = AllServicesLayout.standard
    private let itemsProvider: AllServicesItemsProvider
    private weak var coordinator: AllServicesRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        itemsProvider: AllServicesItemsProvider,
        coordinator: AllServicesRoutable
    ) {
        self.itemsProvider = itemsProvider
        self.coordinator = coordinator

        bind()
    }

    func select(_ item: AllServicesItem) {
        switch item.id {
        case .addWallet:
            coordinator?.openAddWallet()
        }
    }

    func close() {
        coordinator?.closeAllServices()
    }
}

// MARK: - Private

private extension AllServicesViewModel {
    func bind() {
        itemsProvider
            .itemsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, items in
                viewModel.apply(items)
            }
            .store(in: &bag)
    }

    func apply(_ items: [AllServicesItem]) {
        let itemsByID = items.keyedFirst(by: \.id)

        actions = layout.actions.compactMap { itemsByID[$0] }
    }
}
