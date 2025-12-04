//
//  TangemPayNoDepositAddressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

protocol TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet()
}

struct TangemPayNoDepositAddressSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempayServiceUnavailableTitle
    let subtitle = Localization.tangempayCardDetailsReceiveErrorDescription

    let coordinator: TangemPayNoDepositAddressSheetRoutable

    func close() {
        coordinator.closeNoDepositAddressSheet()
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: close
        )
    }
}
