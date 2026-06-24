//
//  CommonCryptoAddressProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import BlockchainSdk

/// Resolves a typed address (incl. ENS) for a single fixed blockchain and keeps the entered address and
/// memo together in a consistent `CryptoAddressProcessorDestination`. The resulting UI state is published
/// via `cryptoAddressViewStatePublisher`; the committed destination is surfaced to the owner via `output`.
/// Name resolution comes from `addressResolver`; address-format validation and `canEmbedAdditionalField`
/// from `validator`. The memo field is built upstream (by the additional-field provider) and handed in
/// already typed.
final class CommonCryptoAddressProcessor {
    private let addressResolver: AddressResolver?
    private let validator: CryptoAddressProcessorValidator
    private let analyticsLogger: CryptoAddressProcessorAnalyticsLogger

    private weak var output: CryptoAddressProcessorOutput?

    private let state = CurrentValueSubject<CryptoAddressViewState, Never>(.empty)
    private var updatingTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        addressResolver: AddressResolver?,
        validator: CryptoAddressProcessorValidator,
        analyticsLogger: CryptoAddressProcessorAnalyticsLogger,
        output: CryptoAddressProcessorOutput?
    ) {
        self.addressResolver = addressResolver
        self.validator = validator
        self.analyticsLogger = analyticsLogger
        self.output = output

        bind()
    }
}

// MARK: - CryptoAddressProcessor

extension CommonCryptoAddressProcessor: CryptoAddressProcessor {
    var cryptoAddressViewStatePublisher: AnyPublisher<CryptoAddressViewState, Never> {
        state.eraseToAnyPublisher()
    }

    func willResolving(address: String) -> Bool {
        addressResolver?.requiresResolution(address: address) ?? false
    }

    @discardableResult
    func update(destination address: String, source: Analytics.DestinationAddressSource) -> Task<Void, Never> {
        updatingTask?.cancel()

        let task = runTask(in: self) { processor in
            await processor.resolveDestination(address: address, source: source)
        }

        updatingTask = task
        return task
    }

    func update(additionalField: SendDestinationAdditionalField?) {
        guard let context = state.value.context else {
            return
        }

        let destination = CryptoAddressProcessorDestination(address: context.destination.address, additionalField: additionalField)
        state.value = makeResolvedState(context: context.with(destination: destination))
    }
}

// MARK: - Private

private extension CommonCryptoAddressProcessor {
    func bind() {
        state
            .map(\.committedDestination)
            .withWeakCaptureOf(self)
            .sink { processor, destination in
                processor.output?.cryptoAddressDidUpdated(to: destination)
            }
            .store(in: &bag)
    }

    func resolveDestination(address: String, source: Analytics.DestinationAddressSource) async {
        guard !address.isEmpty else {
            await runOnMain { state.value = .empty }
            return
        }

        let canEmbedAdditionalField = validator.canEmbedAdditionalField(into: address)

        do {
            try validator.validate(destination: address)
            let resolution = try await resolve(address: address)
            try Task.checkCancellation()

            let addressType: CryptoAddressProcessorDestinationType
            let memoRequired: Bool

            switch resolution {
            case .unresolvable:
                addressType = .address(address)
                memoRequired = false
            case .resolved(let resolved, let resolvedMemoRequired):
                addressType = .resolved(address: address, resolved: resolved)
                memoRequired = resolvedMemoRequired
            }

            await runOnMain {
                // Carry over any memo the user already typed, so re-resolving doesn't drop it.
                let additionalField = state.value.context?.destination.additionalField
                let destination = CryptoAddressProcessorDestination(address: addressType, additionalField: additionalField)

                state.value = makeResolvedState(context: .init(
                    destination: destination,
                    canEmbedAdditionalField: canEmbedAdditionalField,
                    memoRequired: memoRequired
                ))
            }
            analyticsLogger.logSendAddressEntered(isAddressValid: true, addressSource: source)
        } catch is CancellationError {
            // Superseded by a newer address change — keep the current state.
        } catch {
            await runOnMain { state.value = .invalidAddress(message: error.localizedDescription) }
            analyticsLogger.logSendAddressEntered(isAddressValid: false, addressSource: source)
        }
    }

    /// Mirrors `memoValidationBeforeConfirm`: demands the memo / destination tag before the destination is
    /// considered complete; otherwise the destination is `.valid`.
    func makeResolvedState(context: CryptoAddressViewState.Context) -> CryptoAddressViewState {
        if context.memoRequired, context.destination.additionalField?.isFilled != true {
            return .additionalFieldRequired(context)
        }

        return .valid(context)
    }

    func resolve(address: String) async throws -> Resolution {
        guard let addressResolver, addressResolver.requiresResolution(address: address) else {
            return .unresolvable
        }

        do {
            let result = try await addressResolver.resolve(address)
            return .resolved(resolved: result.resolved, memoRequired: result.requiresDestinationTag)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLogger.error("Failed to resolve address", error: error)
            throw CryptoAddressProcessorDestinationError.invalidAddress
        }
    }
}

// MARK: - Resolution

private extension CommonCryptoAddressProcessor {
    enum Resolution {
        case unresolvable
        case resolved(resolved: String, memoRequired: Bool)
    }
}
