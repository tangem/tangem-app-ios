//
//  ExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressDestinationService {
    /// Has a source or destination pair
    func canBeSwapped(wallet: WalletModel) async -> Bool
    func getDestination(source: WalletModel) async throws -> WalletModel
}

enum ExpressDestinationServiceError: Error {
    case destinationNotFound
}
