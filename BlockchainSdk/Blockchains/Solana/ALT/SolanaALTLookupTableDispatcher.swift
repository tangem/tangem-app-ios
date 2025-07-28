//
//  SolanaALTLookupTableDispatcher.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

protocol SolanaALTLookupTableDispatcher {
    /// Creates and extends an Address Lookup Table (ALT) as needed, and waits until all required keys are present.
    /// - Parameters:
    ///   - staticKeys: Public keys that are always required (not chunked).
    ///   - altKeys: Public keys to be added to the ALT (will be chunked if needed).
    /// - Returns: The fully prepared AddressLookupTableAccount, or nil if not all keys are present after polling.
    /// - Throws: BlockchainSdkError if creation or extension fails, or if no keys are provided.
    func dispatchLookupTableAccount(staticKeys: [PublicKey], altKeys: [PublicKey]) async throws -> AddressLookupTableAccount?

    /// Fetches all ALT accounts referenced by the original message.
    /// - Parameter message: The original v0 message.
    /// - Returns: An array of AddressLookupTableAccount objects.
    /// - Throws: If fetching any ALT account fails.
    func prepareExistLookupTableAccounts(message: MessageV0) async throws -> [AddressLookupTableAccount]
}

/// A dispatcher responsible for managing the creation and extension of Address Lookup Tables (ALT) in the Solana blockchain.
/// It handles chunking of public keys, creation of ALT, extension with additional keys, and polling for the complete state.
struct SolanaCommonALTLookupTableDispatcher: SolanaALTLookupTableDispatcher {
    // MARK: - Properties

    /// The wallet's public key, used as authority and payer for ALT operations.
    private let walletPublicKey: PublicKey
    /// Service for interacting with the Solana network (fetching ALT, etc.).
    private let networkService: SolanaNetworkService
    /// Responsible for creating and extending ALT accounts.
    private let lookupTableCreator: SolanaALTLookupTableCreator

    // MARK: - Init

    /// Initializes the dispatcher with required dependencies.
    /// - Parameters:
    ///   - walletPublicKey: The public key of the wallet (authority and payer).
    ///   - networkService: Service for Solana network operations.
    ///   - lookupTableCreator: Service for creating/extending ALT accounts.
    init(walletPublicKey: PublicKey, networkService: SolanaNetworkService, lookupTableCreator: SolanaALTLookupTableCreator) {
        self.walletPublicKey = walletPublicKey
        self.networkService = networkService
        self.lookupTableCreator = lookupTableCreator
    }

    // MARK: - Implementation

    func dispatchLookupTableAccount(staticKeys: [PublicKey], altKeys: [PublicKey]) async throws -> AddressLookupTableAccount? {
        let altKeyСhunks: [[PublicKey]] = stride(from: 0, to: altKeys.count, by: Constants.maxKeysPerALTLookupTable).map {
            Array(altKeys[$0 ..< min($0 + Constants.maxKeysPerALTLookupTable, altKeys.count)])
        }

        guard let toCreateTableAccountKeys = altKeyСhunks.first else {
            throw BlockchainSdkError.failedToFindTxInputs
        }

        let createdLookupTableAccount = try await lookupTableCreator.createLookupTableAccounts(
            accountKeys: toCreateTableAccountKeys,
            authority: walletPublicKey,
            payer: walletPublicKey
        )

        let createLookupTableAccountAddress = createdLookupTableAccount.key

        // 7. Extend the lookup table with additional keys if needed
        try await extendedLookupTableAccountIfNeeded(
            with: altKeyСhunks,
            to: createLookupTableAccountAddress,
            existedKeys: createdLookupTableAccount.state.addresses
        )

        // 8. Poll for the complete state of the ALT, waiting for all addresses to appear
        let extendedLookupTableAccount = try await expectCompleteStateLookupTableAccount(from: createLookupTableAccountAddress, expectedKeys: altKeys)

        return extendedLookupTableAccount
    }

    /// Fetches all ALT accounts referenced by the original message.
    /// - Parameter message: The original v0 message.
    /// - Returns: An array of AddressLookupTableAccount objects.
    /// - Throws: If fetching any ALT account fails.
    func prepareExistLookupTableAccounts(message: MessageV0) async throws -> [AddressLookupTableAccount] {
        var initiaLookupAccounts: [AddressLookupTableAccount] = []

        for lookup in message.addressTableLookups {
            let altAccount = try await networkService.getAddressLookupTable(accountKey: lookup.accountKey)
            initiaLookupAccounts.append(altAccount)
        }

        return initiaLookupAccounts
    }

    // MARK: - Private Implementation

    /// Extends the ALT with additional keys, ensuring no duplicates are added.
    /// - Parameters:
    ///   - keys: Chunks of public keys to add (excluding the first chunk, which is used for creation).
    ///   - account: The ALT account public key to extend.
    ///   - existedKeys: The set of public keys already present in the ALT.
    /// - Throws: If extension fails.
    private func extendedLookupTableAccountIfNeeded(
        with keys: [[PublicKey]],
        to account: PublicKey,
        existedKeys: [PublicKey]
    ) async throws {
        guard keys.count > 1 else {
            return
        }

        var existedKeysSet = Set(existedKeys)

        for keyAddresses in keys.dropFirst() {
            // Exclude keys that already exist in the ALT
            let filteredAddresses = keyAddresses.filter { !existedKeysSet.contains($0) }
            guard !filteredAddresses.isEmpty else { continue }

            BSDKLogger.debug("ALT: Extending ALT table \(account.base58EncodedString) with keys: \(filteredAddresses.map { $0.base58EncodedString })")

            _ = try await lookupTableCreator.extendedLookupTableAccounts(
                lookupTableAddress: account,
                authority: walletPublicKey,
                payer: walletPublicKey,
                addresses: filteredAddresses
            )

            // Update the set of existing keys after each extension
            existedKeysSet.formUnion(filteredAddresses)
        }
    }

    /// Polls the ALT until all expected keys are present or the maximum number of attempts is reached.
    /// - Parameters:
    ///   - account: The ALT account public key to poll.
    ///   - expectedKeys: The set of public keys expected to be present in the ALT.
    /// - Returns: The ALT account if all keys are present, or nil otherwise.
    /// - Throws: If polling fails.
    private func expectCompleteStateLookupTableAccount(from account: PublicKey, expectedKeys: [PublicKey]) async throws -> AddressLookupTableAccount? {
        let expectedALTCount = expectedKeys.count

        var resultLookupTableAccount: AddressLookupTableAccount?

        for attempt in 0 ..< Constants.maxAttempExpectCompletionALTAddresses {
            let addressLookupTableAccount = try await networkService.getAddressLookupTable(accountKey: account)
            let addresses = addressLookupTableAccount.state.addresses

            BSDKLogger.debug("ALT: [POLL] attempt \(attempt): ALT has \(addresses.count)/\(expectedALTCount) addresses")

            // Check if all required keys are present in the ALT
            let lookupTableAddressesSet = Set(addresses)
            let expectedAltSet = Set(expectedKeys)
            let missing = expectedAltSet.subtracting(lookupTableAddressesSet)

            guard missing.isEmpty else {
                BSDKLogger.warning("ALT: missing addresses: \(missing.count)/\(expectedAltSet.count) not found")
                try await Task.sleep(nanoseconds: Constants.waitTimeBetweenALTAddressesExpectCompletion)
                continue
            }

            resultLookupTableAccount = addressLookupTableAccount
            break
        }

        if let resultLookupTableAccount {
            BSDKLogger.debug("ALT: lookup table key: \(resultLookupTableAccount.key.base58EncodedString)")

            for (idx, addr) in resultLookupTableAccount.state.addresses.enumerated() {
                BSDKLogger.debug("ALT: Lookup Table Addresses [\(idx)]: \(addr.base58EncodedString)")
            }
        }

        return resultLookupTableAccount
    }
}

extension SolanaCommonALTLookupTableDispatcher {
    /// Constants used for ALT creation and polling.
    enum Constants {
        /// Maximum number of keys per ALT chunk (Solana protocol limit).
        static let maxKeysPerALTLookupTable: Int = 14
        /// Maximum number of polling attempts for ALT completion.
        static let maxAttempExpectCompletionALTAddresses: Int = 15
        /// Wait time (in nanoseconds) between polling attempts.
        static let waitTimeBetweenALTAddressesExpectCompletion: UInt64 = 5_000_000_000 // 5 sec
    }
}

// MARK: - Dummy

struct SolanaDummyALTLookupTableDispatcher: SolanaALTLookupTableDispatcher {
    private let lookupTableAccountKey: String
    private let lookupTableAccountDecodeState: Data

    init(lookupTableAccountKey: String, lookupTableAccountDecodeState: Data) {
        self.lookupTableAccountKey = lookupTableAccountKey
        self.lookupTableAccountDecodeState = lookupTableAccountDecodeState
    }

    func dispatchLookupTableAccount(staticKeys: [PublicKey], altKeys: [PublicKey]) async throws -> AddressLookupTableAccount? {
        let key = PublicKey(string: lookupTableAccountKey)!
        let state = try JSONDecoder().decode(AddressLookupTableState.self, from: lookupTableAccountDecodeState)
        return AddressLookupTableAccount(key: key, state: state)
    }

    func prepareExistLookupTableAccounts(message: MessageV0) async throws -> [AddressLookupTableAccount] {
        return []
    }
}
