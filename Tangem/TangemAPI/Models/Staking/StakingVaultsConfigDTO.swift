//
//  StakingVaultsConfigDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum StakingVaultsConfigDTO {
    struct Response: Decodable {
        let vaults: [Vault]
    }

    struct Vault: Decodable {
        let vaultAddress: String
        @FlexibleDecimal var limit: Decimal?
        /// Reserved for future use
        @FlexibleDecimal var coefficient: Decimal?
    }
}
