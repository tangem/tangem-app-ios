//
//  DynamicAddressesEnterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

final class DynamicAddressesEnterViewModel: ObservableObject, Identifiable {
    @Published private(set) var mainButtonIsLoading: Bool = false
    @Published private(set) var mainButtonIsDisabled: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?

    @Published var alert: AlertBinder?

    private let walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider
    private weak var coordinator: DynamicAddressesEnterRoutable?

    private var enablingTask: Task<Void, Never>?

    init(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        coordinator: DynamicAddressesEnterRoutable
    ) {
        self.walletModelDynamicAddressesProvider = walletModelDynamicAddressesProvider
        self.coordinator = coordinator

        setupView()
    }

    // MARK: - Actions

    func userDidTapEnableAction() {
        mainButtonIsLoading = true
        enablingTask?.cancel()
        enablingTask = Task { [weak self] in
            await self?.enableDynamicAddresses()
        }
    }

    func close() {
        enablingTask?.cancel()
        dismiss(isSuccess: false)
    }
}

// MARK: - Private

private extension DynamicAddressesEnterViewModel {
    func enableDynamicAddresses() async {
        do {
            try await walletModelDynamicAddressesProvider.enableDynamicAddresses()
            try Task.checkCancellation()

            await MainActor.run {
                mainButtonIsLoading = false
                dismiss(isSuccess: true)
            }
        } catch is CancellationError {
            // Do nothing
        } catch {
            await MainActor.run {
                mainButtonIsLoading = false
                alert = error.alertBinder
            }
        }
    }

    private func setupView() {
        switch walletModelDynamicAddressesProvider.dynamicAddressesEnablingRequirements {
        case .none:
            mainButtonIcon = nil
            mainButtonIsDisabled = false

        case .xpubDerivationIsNeeded:
            mainButtonIcon = .trailing(Assets.tangemIcon)
            mainButtonIsDisabled = false

        case .customTokensRemoveIsNeeded:
            mainButtonIsDisabled = true
        }
    }

    func dismiss(isSuccess: Bool) {
        coordinator?.closeDynamicAddressesEnterView()
        if isSuccess {
            showSuccessToast()
        }
    }

    private func showSuccessToast() {
        Toast(view: SuccessToast(text: Localization.dynamicAddressesEnabledToastTitle))
            .present(
                layout: .top(),
                type: .temporary()
            )
    }
}
