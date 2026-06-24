//
//  CryptoAddressProcessorDestination.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

/// The resolved destination produced by `CommonCryptoAddressProcessor`: the entered/resolved
/// address plus the entered memo / destination-tag field.
struct CryptoAddressProcessorDestination {
    let address: CryptoAddressProcessorDestinationType
    let additionalField: SendDestinationAdditionalField?
}

enum CryptoAddressProcessorDestinationType: Equatable {
    /// A plain address the user typed.
    case address(String)
    /// A name (e.g. ENS) the user typed, plus the address it resolved to.
    case resolved(address: String, resolved: String)

    /// The address the user typed.
    var typedAddress: String {
        switch self {
        case .address(let address): address
        case .resolved(let address, _): address
        }
    }

    /// The address to use as the transaction / saved destination.
    var transactionAddress: String {
        switch self {
        case .address(let address): address
        case .resolved(_, let resolved): resolved
        }
    }

    /// The resolved address to surface to the user; nil when it equals the typed one.
    var showableResolved: String? {
        switch self {
        case .address: nil
        case .resolved(let address, let resolved): address == resolved ? nil : resolved
        }
    }
}

enum CryptoAddressProcessorDestinationError {
    /// The address is empty or doesn't resolve to a valid address.
    case invalidAddress
}

extension CryptoAddressProcessorDestinationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return Localization.sendRecipientAddressError
        }
    }
}
