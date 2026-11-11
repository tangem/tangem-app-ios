//
//  DerivationManagerError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum DerivationManagerError: LocalizedError {
    case keysDerivingProviderNotFound

    var errorDescription: String? {
        Localization.genericErrorCode(errorCode)
    }
}
