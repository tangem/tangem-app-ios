//
//  CryptoAddressProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol CryptoAddressProcessor {
    var cryptoAddressViewStatePublisher: AnyPublisher<CryptoAddressViewState, Never> { get }

    func willResolving(address: String) -> Bool

    @discardableResult
    func update(destination: String, source: Analytics.DestinationAddressSource) -> Task<Void, Never>
    func update(additionalField: SendDestinationAdditionalField?)
}

/// The UI-facing outcome of a destination / additional-field update.
enum CryptoAddressViewState {
    /// Nothing entered.
    case empty

    /// The typed address is invalid; `message` is shown on the address field.
    case invalidAddress(message: String)

    /// The address is valid but the destination requires a memo / destination tag that isn't entered yet.
    case additionalFieldRequired(Context)

    /// The address is valid and complete (any required memo / destination tag is filled in).
    case valid(Context)

    /// The resolution context shared by the resolved states. Carries everything needed to recompute the
    /// state when the memo changes — without re-resolving the address.
    struct Context {
        let destination: CryptoAddressProcessorDestination
        /// False when the address already embeds the memo / destination tag.
        let canEmbedAdditionalField: Bool
        /// Whether the resolved destination demands a memo / destination tag.
        let memoRequired: Bool

        func with(destination: CryptoAddressProcessorDestination) -> Context {
            Context(destination: destination, canEmbedAdditionalField: canEmbedAdditionalField, memoRequired: memoRequired)
        }
    }

    /// The resolution context for the resolved states; nil for `.empty` / `.invalidAddress`.
    var context: Context? {
        switch self {
        case .additionalFieldRequired(let context), .valid(let context): context
        case .empty, .invalidAddress: nil
        }
    }

    /// The destination to commit to the owner — present only once the address (and any required memo) is complete.
    var committedDestination: CryptoAddressProcessorDestination? {
        guard case .valid(let context) = self else { return nil }
        return context.destination
    }
}

// MARK: - Output

protocol CryptoAddressProcessorOutput: AnyObject {
    func cryptoAddressDidUpdated(to destination: CryptoAddressProcessorDestination?)
}
