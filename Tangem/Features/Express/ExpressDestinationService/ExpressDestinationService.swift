//
//  ExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressDestinationService {
    func getDestination(source: any ExpressInteractorSourceWallet) async throws -> any ExpressInteractorSourceWallet
}

enum ExpressDestinationServiceError: Error {
    case destinationNotFound
}
