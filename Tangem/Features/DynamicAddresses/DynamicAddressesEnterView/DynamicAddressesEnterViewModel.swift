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

    private let dynamicAddressesManager: DynamicAddressesManager
    private let walletModelUpdater: WalletModelUpdater
    private weak var coordinator: DynamicAddressesEnterRoutable?

    private var enablingTask: Task<Void, Never>?

    init(
        dynamicAddressesManager: DynamicAddressesManager,
        walletModelUpdater: WalletModelUpdater,
        coordinator: DynamicAddressesEnterRoutable
    ) {
        self.dynamicAddressesManager = dynamicAddressesManager
        self.walletModelUpdater = walletModelUpdater
        self.coordinator = coordinator

        assert(
            dynamicAddressesManager.state.isDisabled,
            "DynamicAddressesEnterView should be used only in disabled state"
        )

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
            try await dynamicAddressesManager.enableDynamicAddresses()
            walletModelUpdater.setNeedsUpdate()
            walletModelUpdater.startUpdateTask(silent: false)

            await MainActor.run {
                mainButtonIsLoading = false
                dismiss(isSuccess: true)
            }
        } catch is CancellationError {
            // Do nothing
        } catch {
            await MainActor.run { alert = error.alertBinder }
        }
    }

    private func setupView() {
        switch dynamicAddressesManager.enablingRequirements {
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
