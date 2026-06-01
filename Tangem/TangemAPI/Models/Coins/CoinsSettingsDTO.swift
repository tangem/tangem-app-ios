//
//  CoinsSettingsDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum CoinsSettingsDTO {
    struct Response: Decodable {
        let staking: Staking?
    }

    struct Staking: Decodable {
        let vaults: [Vault]
    }

    struct Vault: Decodable {
        let vaultAddress: String
        @FlexibleDecimal var limit: Decimal?
        @FlexibleDecimal var coefficient: Decimal?
    }
}
