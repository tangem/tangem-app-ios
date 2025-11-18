//
//  P2PDTO+Vault.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum Vaults {
        typealias Response = GenericResponse<VaultsInfo>

        struct Vault: Decodable {
            let vaultAddress: String
            let displayName: String
            let apy: Decimal
            let baseApy: Decimal
            let capacity: Decimal
            let totalAssets: Decimal
            let feePercent: Decimal
            let isPrivate: Bool
            let isGenesis: Bool
            let isSmoothingPool: Bool
            let isErc20: Bool
            let tokenName: String?
            let tokenSymbol: String?
            let createdAt: Data
        }

        struct VaultsInfo: Decodable {
            let network: String
            let vaults: [Vault]
        }
    }
}
