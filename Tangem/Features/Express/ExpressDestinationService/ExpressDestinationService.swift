//
//  ExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressDestinationService {
    func getDestination(source: any WalletModel) async throws -> any WalletModel
}

enum ExpressDestinationServiceError: Error {
    case destinationNotFound
}
