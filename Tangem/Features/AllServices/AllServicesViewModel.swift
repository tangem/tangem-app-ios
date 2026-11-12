//
//  AllServicesViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization

final class AllServicesViewModel: ObservableObject {
    @Published private(set) var sections: [Section] = []
    @Published private(set) var isReferralAvailable = false

    // [REDACTED_TODO_COMMENT]
    let title = "All services"
    let subtitle = "Everything available to you in one place.\nAdd what you need, when you need it."
    let referralAccessibilityLabel = Localization.detailsReferralTitle
    let actions: [AllServicesAction]

    private let layout = AllServicesLayout.standard
    private let itemsProvider: AllServicesItemsProvider
    private let referralEntryProvider: ReferralServiceEntryProvider
    private weak var coordinator: AllServicesRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        itemsProvider: AllServicesItemsProvider,
        referralEntryProvider: ReferralServiceEntryProvider,
        coordinator: AllServicesRoutable
    ) {
        self.itemsProvider = itemsProvider
        self.referralEntryProvider = referralEntryProvider
        self.coordinator = coordinator
        actions = itemsProvider.actions

        bind()
    }

    func select(_ action: AllServicesAction) {
        switch action.id {
        case .addWallet:
            coordinator?.openAddWallet()
        case .buyTangem:
            coordinator?.openShop()
        }
    }

    func select(_ item: AllServicesItem) {
        switch item.id {
        case .cryptoAccount:
            coordinator?.openCryptoAccountForm()
        case .jointAccount:
            coordinator?.openJointAccountCreation()
        }
    }

    func openReferral() {
        coordinator?.openReferral(wallets: referralEntryProvider.wallets)
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

        referralEntryProvider
            .isAvailablePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAvailable in
                viewModel.isReferralAvailable = isAvailable
            }
            .store(in: &bag)
    }

    func apply(_ items: [AllServicesItem]) {
        let itemsByID = items.keyedFirst(by: \.id)

        sections = layout.sections.compactMap { section in
            let rows = section.items.compactMap { itemsByID[$0] }
            return rows.isEmpty ? nil : Section(id: section.id, title: section.id.title, items: rows)
        }
    }
}

// MARK: - Section

extension AllServicesViewModel {
    struct Section: Identifiable {
        let id: AllServicesSectionID
        let title: String
        let items: [AllServicesItem]
    }
}

// MARK: - Section titles

private extension AllServicesSectionID {
    var title: String {
        switch self {
        case .account: Localization.commonAccount
        }
    }
}
