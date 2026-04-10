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
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    var icon: BottomSheetErrorContentView.Icon { .attention }
    var title: String { Localization.dynamicAddressesDisableTitle }
    var subtitle: String { Localization.dynamicAddressesDisableDescription }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: Localization.commonConfirm, action: confirm)
    }

    private let dynamicAddressesManager: DynamicAddressesManager
    private weak var coordinator: (any DynamicAddressesDisableSheetRoutable)?

    init(
        dynamicAddressesManager: DynamicAddressesManager,
        coordinator: any DynamicAddressesDisableSheetRoutable
    ) {
        self.dynamicAddressesManager = dynamicAddressesManager
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeDynamicAddressesDisableSheet()
    }

    private func confirm() {
        do {
            try dynamicAddressesManager.disableDynamicAddresses()
            close()
        } catch {
            alertPresenter.present(alert: error.alertBinder)
        }
    }
}
