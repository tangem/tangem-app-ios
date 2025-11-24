//
//  P2PDTO+Vault.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension P2PDTO {
    enum Vaults {
        typealias Response = GenericResponse<VaultsInfo>

        struct Vault: Decodable {
            let vaultAddress: String
            let displayName: String
            @FlexibleDecimal var apy: Decimal?
            @FlexibleDecimal var baseApy: Decimal?
            @FlexibleDecimal var capacity: Decimal?
            @FlexibleDecimal var totalAssets: Decimal?
            @FlexibleDecimal var feePercent: Decimal?
            let isPrivate: Bool
            let isGenesis: Bool
            let isSmoothingPool: Bool
            let isErc20: Bool
            let tokenName: String?
            let tokenSymbol: String?
            let createdAt: Date
        }

        struct VaultsInfo: Decodable {
            let network: String
            let vaults: [Vault]
        }
    }
}
