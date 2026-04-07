//
//  DynamicAddressesDisableSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemUIUtils
import TangemLocalization

protocol DynamicAddressesDisableSheetRoutable: AnyObject {
    func closeDynamicAddressesDisableSheet()
}

final class DynamicAddressesDisableSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var alert: AlertBinder?

    var icon: BottomSheetErrorContentView.Icon { .attention }
    var title: String { Localization.dynamicAddressesDisableTitle }
    var subtitle: String { Localization.dynamicAddressesDisableDescription }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: Localization.commonConfirm, action: confirm)
    }

    private let dynamicAddressesManager: DynamicAddressesManager
    private let walletModelUpdater: WalletModelUpdater
    private weak var coordinator: (any DynamicAddressesDisableSheetRoutable)?

    init(
        dynamicAddressesManager: DynamicAddressesManager,
        walletModelUpdater: WalletModelUpdater,
        coordinator: any DynamicAddressesDisableSheetRoutable
    ) {
        self.dynamicAddressesManager = dynamicAddressesManager
        self.walletModelUpdater = walletModelUpdater
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeDynamicAddressesDisableSheet()
    }

    private func confirm() {
        do {
            try dynamicAddressesManager.disableDynamicAddresses()
            walletModelUpdater.setNeedsUpdate()
            walletModelUpdater.startUpdateTask(silent: false)
            close()
        } catch {
            alert = error.alertBinder
        }
    }
}
