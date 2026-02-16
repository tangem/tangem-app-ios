//
//  ExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressDestinationService {
    func getSource(destination: TokenItem) async throws -> any ExpressInteractorSourceWallet
    func getDestination(source: TokenItem) async throws -> any ExpressInteractorSourceWallet

    func getSource(destination: TokenItem) async throws -> any SwapSourceToken
    func getDestination(source: TokenItem) async throws -> any SwapSourceToken
}

enum ExpressDestinationServiceError: Error {
    case sourceNotFound(destination: TokenItem)
    case destinationNotFound(source: TokenItem)
}
