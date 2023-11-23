//
//  ManageTokensSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

struct ManageTokensSettings {
    let longHashesSupported: Bool
    let existingCurves: [EllipticCurve]
}
