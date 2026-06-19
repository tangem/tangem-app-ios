//
//  CommonCryptoAddressProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

/// Resolves a typed address (incl. ENS) for a single fixed blockchain and keeps the entered address and
/// memo together in a consistent `CryptoAddressProcessorDestination`, surfaced to the owner via `output`.
/// Name resolution comes from `addressResolver`; address-format validation and `canEmbedAdditionalField`
/// from `validator`. The memo field is built upstream (by the additional-field provider) and handed in
/// already typed.
final class CommonCryptoAddressProcessor {
    private let addressResolver: AddressResolver?
    private let validator: CryptoAddressProcessorValidator

    private weak var output: CryptoAddressProcessorOutput?

    private let state = OSAllocatedUnfairLock<State>(initialState: .init())

    init(
        addressResolver: AddressResolver?,
        validator: CryptoAddressProcessorValidator,
        output: CryptoAddressProcessorOutput?
    ) {
        self.addressResolver = addressResolver
        self.validator = validator
        self.output = output
    }
}

// MARK: - CryptoAddressProcessor

extension CommonCryptoAddressProcessor: CryptoAddressProcessor {
    func willResolving(address: String) -> Bool {
        addressResolver?.requiresResolution(address: address) ?? false
    }

    @MainActor
    func update(destination address: String, source: Analytics.DestinationAddressSource) async throws -> CryptoAddressParameters {
        guard !address.isEmpty else {
            apply { $0.addressType = nil }
            return CryptoAddressParameters(resolvedAddress: nil, memoIsRequired: false, canEmbedAdditionalField: true)
        }

        let canEmbedAdditionalField = validator.canEmbedAdditionalField(into: address)
        try validator.validate(destination: address)

        let resolution = try await resolve(address: address)
        let addressType: CryptoAddressProcessorDestinationType = {
            if resolution.resolved == address {
                return .address(address)
            }

            return .resolved(address: address, resolved: resolution.resolved)
        }()

        apply { $0.addressType = addressType }
        let isAdditionalFieldFilled = state { $0.additionalField }?.isFilled == true

        return CryptoAddressParameters(
            resolvedAddress: addressType.showableResolved,
            memoIsRequired: resolution.memoRequired && !isAdditionalFieldFilled,
            canEmbedAdditionalField: canEmbedAdditionalField
        )
    }

    func update(additionalField: SendDestinationAdditionalField?) {
        apply { $0.additionalField = additionalField }
    }
}

// MARK: - Private

private extension CommonCryptoAddressProcessor {
    struct Resolution {
        let resolved: String
        let memoRequired: Bool
    }

    func resolve(address: String) async throws -> Resolution {
        guard let addressResolver, addressResolver.requiresResolution(address: address) else {
            return Resolution(resolved: address, memoRequired: false)
        }

        do {
            let result = try await addressResolver.resolve(address)
            return Resolution(resolved: result.resolved, memoRequired: result.requiresDestinationTag)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLogger.error("Failed to resolve address", error: error)
            throw CryptoAddressProcessorDestinationError.invalidAddress
        }
    }

    func apply(_ mutate: (inout State) -> Void) {
        let destination = state { state -> CryptoAddressProcessorDestination? in
            mutate(&state)
            return state.addressType.map { addressType in
                CryptoAddressProcessorDestination(address: addressType, additionalField: state.additionalField)
            }
        }

        output?.cryptoAddressDidUpdated(to: destination)
    }
}

// MARK: - CryptoAddressProcessor

extension CommonCryptoAddressProcessor {
    struct State {
        var addressType: CryptoAddressProcessorDestinationType?
        var additionalField: SendDestinationAdditionalField?
    }
}
