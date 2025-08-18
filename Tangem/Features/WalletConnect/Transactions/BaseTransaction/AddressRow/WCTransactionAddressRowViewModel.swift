//
//  WCTransactionAddressRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum TangemAssets.Assets
import enum TangemLocalization.Localization

struct WCTransactionAddressRowViewModel {
    let icon = Assets.Glyphs.userSquare
    let label = Localization.wcCommonAddress
    let address: String
}
