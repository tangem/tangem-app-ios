//
//  HotAccessCodeResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemHotSdk

enum HotAccessCodeResult {
    /// Access code was successfully entered.
    case accessCodeSuccessfull(MobileWalletContext)
    /// Sent a request for biometrics.
    case biometricsRequest
    /// User tapped "Close" on the access code screen.
    case closed
    /// Access code screen was manually dismissed (e.g. swiped down).
    case dismissed
    /// Unavailable due wallet needs to be deleted.
    case unavailableDueToDeletion
}
