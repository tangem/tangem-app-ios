//
//  LegacyManageTokensSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

struct LegacyManageTokensSettings {
    let supportedBlockchains: Set<Blockchain>
    let hdWalletsSupported: Bool
    let longHashesSupported: Bool
    let derivationStyle: DerivationStyle?
    let shouldShowLegacyDerivationAlert: Bool
    let existingCurves: [EllipticCurve]
}
