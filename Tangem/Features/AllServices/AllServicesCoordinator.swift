//
//  AllServicesCoordinator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class AllServicesCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AllServicesViewModel?

    // MARK: - Child coordinators

    @Published var addWalletSelectorCoordinator: AddWalletSelectorCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AllServicesViewModel(
            itemsProvider: AllServicesItemsProvider(),
            coordinator: self
        )
    }
}

// MARK: - AllServicesRoutable

extension AllServicesCoordinator: AllServicesRoutable {
    func openAddWallet() {
        let dismissAction: Action<AddWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.dismiss()
            }
        }

        let coordinator = AddWalletSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(source: .allServices))
        addWalletSelectorCoordinator = coordinator
    }

    func closeAllServices() {
        dismiss()
    }
}

// MARK: - Options

extension AllServicesCoordinator {
    struct Options {}
}
