//
//  CardScannerParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardScannerParameters {
    let shouldAskForAccessCodes: Bool
    let performDerivations: Bool
    let sessionFilter: SessionFilter?
}
