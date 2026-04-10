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

    private weak var coordinator: DynamicAddressesEnterRoutable?

    init(coordinator: DynamicAddressesEnterRoutable) {
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func userDidTapEnableAction() {
        mainButtonIsLoading = true
        Task {
            try await Task.sleep(for: .seconds(2))
            await MainActor.run {
                close()
                showSuccessToast()
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
