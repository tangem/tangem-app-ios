//
//  CryptoAddressProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol CryptoAddressProcessor {
    func willResolving(address: String) -> Bool

    @MainActor
    func update(destination: String, source: Analytics.DestinationAddressSource) async throws -> CryptoAddressParameters
    func update(additionalField: SendDestinationAdditionalField?)
}

struct CryptoAddressParameters {
    let resolvedAddress: String?
    let memoIsRequired: Bool
    let canEmbedAdditionalField: Bool
}

// MARK: - Output

protocol CryptoAddressProcessorOutput: AnyObject {
    func cryptoAddressDidUpdated(to destination: CryptoAddressProcessorDestination?)
}
