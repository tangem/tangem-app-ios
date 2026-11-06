//
//  DerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol DerivationManager: PendingDerivationStatusProvider {
    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool
    func deriveKeys() async throws
}
