//
//  DynamicAddressesEnterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

final class DynamicAddressesEnterViewModel: ObservableObject, Identifiable {
    @Published private(set) var mainButtonIsLoading: Bool = false

    private let dynamicAddressesManager: DynamicAddressesManager
    private let walletModelUpdater: WalletModelUpdater
    private weak var coordinator: DynamicAddressesEnterRoutable?

    init(
        dynamicAddressesManager: DynamicAddressesManager,
        walletModelUpdater: WalletModelUpdater,
        coordinator: DynamicAddressesEnterRoutable
    ) {
        self.dynamicAddressesManager = dynamicAddressesManager
        self.walletModelUpdater = walletModelUpdater
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func userDidTapEnableAction() {
        mainButtonIsLoading = true
        Task {
            do {
                try await dynamicAddressesManager.enableDynamicAddresses()
                await walletModelUpdater.startUpdateTask().value

                await MainActor.run { close(); showSuccessToast() }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }

    func close() {
        coordinator?.closeDynamicAddressesEnterView()
    }

    func showSuccessToast() {
        Toast(view: SuccessToast(text: Localization.dynamicAddressesEnabledToastTitle))
            .present(
                layout: .top(),
                type: .temporary()
            )
    }
}
