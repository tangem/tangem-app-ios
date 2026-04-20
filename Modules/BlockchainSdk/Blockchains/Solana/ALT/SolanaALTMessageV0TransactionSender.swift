//
//  SolanaALTMessageV0TransactionSender.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import TangemFoundation

/// Responsible for rebuilding and sending Solana v0 transactions using Address Lookup Tables (ALT).
/// Handles splitting static and ALT keys, creating and extending ALT tables, remapping instructions, and sending the transaction.
struct SolanaALTMessageV0TransactionSender {
    // MARK: - Properties

    private let walletPublicKey: PublicKey
    private let accountKeysSplitProvider: SolanaAccountKeysSplitProvider
    private let sendBuilder: SolanaALTSendTransactionBuilder
    private let blockhashProvider: SolanaALTBlockhashProvider
    private let lookupTableDispatcher: SolanaALTLookupTableDispatcher

    // MARK: - Init

    init(
        walletPublicKey: PublicKey,
        accountKeysSplitProvider: SolanaAccountKeysSplitProvider,
        sendBuilder: SolanaALTSendTransactionBuilder,
        blockhashProvider: SolanaALTBlockhashProvider,
        lookupTableDispatcher: SolanaALTLookupTableDispatcher
    ) {
        self.walletPublicKey = walletPublicKey
        self.accountKeysSplitProvider = accountKeysSplitProvider
        self.sendBuilder = sendBuilder
        self.blockhashProvider = blockhashProvider
        self.lookupTableDispatcher = lookupTableDispatcher
    }

    // MARK: - Implementation

    /// Rebuilds and sends a Solana v0 transaction using a single ALT table, creating and extending it as needed.
    /// - Parameter message: The original v0 message to be rebuilt and sent.
    /// - Returns: The transaction ID of the sent transaction.
    /// - Throws: An error if the ALT table cannot be created/extended, or if the transaction fails to send.
    @discardableResult
    mutating func buildForSend(message: MessageV0) async throws -> String {
        // Fetch all ALT accounts referenced by the original message
        let initialLookupAccounts = try await lookupTableDispatcher.prepareExistLookupTableAccounts(message: message)

        // Get the full list of all keys actually used in the transaction
        let allKeys = try message.getAccountKeys(addressLookupTableAccounts: initialLookupAccounts).keySegments.reduce([], +)

        // Build a new message with these keys as staticAccountKeys
        var newMessage = message
        newMessage.staticAccountKeys = allKeys

        // Split into new static and ALT keys
        let (staticAccounts, toAlt) = accountKeysSplitProvider.splitStaticAccountKeys(v0: newMessage)
        let staticAccountKeys = staticAccounts.map { $0.0 }

        // Rebuild header message with new writable / readable
        newMessage.header = recalculateHeader(message: message, staticAccountKeys: staticAccounts)

        // Create or extend the ALT table as needed
        let targetLookupTableAccount = try await lookupTableDispatcher.dispatchLookupTableAccount(staticKeys: staticAccountKeys.map { $0 }, altKeys: toAlt.map { $0 })
        BSDKLogger.debug("ALT: Created lookup table account with key: \(targetLookupTableAccount?.key.base58EncodedString ?? "")")

        guard let targetLookupTableAccount else {
            BSDKLogger.error(error: "ALT: [POLL] ERROR: ALT table did not contain all required addresses after polling")
            throw Error.keyNotFoundInStaticOrAnyALT
        }

        // Use only those keys that are actually present in the ALT table and not in staticAccountKeys
        let staticSet = Set(staticAccountKeys)
        let altKeys = targetLookupTableAccount.state.addresses.filter { !staticSet.contains($0) }

        let newRecentBlockhash = try await blockhashProvider.provideBlockhash()
        BSDKLogger.debug("ALT: Updated latest blockhash for send transaction Base64: \(newRecentBlockhash)")

        // Get the old allKeys (before ALT rebuild)
        let oldAllKeys = try message.getAccountKeys(
            addressLookupTableAccounts: initialLookupAccounts
        ).keySegments.reduce([], +)

        // Remap new keys
        let newAllKeys = staticAccountKeys + altKeys

        // Rebuild the transaction with a single ALT table (only altKeys, no static)
        let targetMessageV0: MessageV0

        do {
            // Build address table lookups
            let addressTableLookups = buildAddressTableLookups(message: newMessage, oldAllKeys: oldAllKeys, altKeys: altKeys, targetLookupTableAccount: targetLookupTableAccount)

            // Remap compiled instructions
            let compiledInstructions = try remapCompiledInstructions(message: message, oldAllKeys: oldAllKeys, newAllKeys: newAllKeys)

            // Build new MessageV0
            targetMessageV0 = buildMessageV0(header: newMessage.header, staticAccountKeys: staticAccountKeys, recentBlockhash: newRecentBlockhash, compiledInstructions: compiledInstructions, addressTableLookups: addressTableLookups)

        } catch {
            BSDKLogger.error(error.localizedDescription, error: error)
            throw error
        }

        // Build and send the transaction
        let buildForSend = try await sendBuilder.buildForSend(message: targetMessageV0)

        return buildForSend.base64EncodedString()
    }
}

// MARK: - Private Implementation

private extension SolanaALTMessageV0TransactionSender {
    /// Builds the address table lookups for the transaction.
    /// - Parameters:
    ///   - message: The original v0 message.
    ///   - oldAllKeys: The list of all keys before ALT rebuild.
    ///   - altKeys: The keys to be included in the ALT table.
    ///   - targetLookupTableAccount: The ALT table account.
    /// - Returns: An array of MessageAddressTableLookup objects.
    func buildAddressTableLookups(message: MessageV0, oldAllKeys: [PublicKey], altKeys: [PublicKey], targetLookupTableAccount: AddressLookupTableAccount) -> [MessageAddressTableLookup] {
        var writableSet = Set<PublicKey>()
        var readonlySet = Set<PublicKey>()
        for instr in message.compiledInstructions {
            for (_, keyIdx) in instr.accountKeyIndexes.enumerated() {
                let keyIndex = Int(keyIdx)
                let key = oldAllKeys[keyIndex]

                guard altKeys.contains(key) else { continue }

                BSDKLogger.debug("ALT Lookups: \(key.base58EncodedString)")

                let isWritable = message.isAccountWritable(index: keyIndex)

                if isWritable {
                    writableSet.insert(key)
                } else {
                    readonlySet.insert(key)
                }
            }
        }
        let writableIndexes: [UInt8] = altKeys.enumerated().compactMap { idx, key in
            writableSet.contains(key) ? UInt8(idx) : nil
        }
        let readonlyIndexes: [UInt8] = altKeys.enumerated().compactMap { idx, key in
            readonlySet.contains(key) && !writableSet.contains(key) ? UInt8(idx) : nil
        }
        return [
            MessageAddressTableLookup(
                accountKey: targetLookupTableAccount.key,
                writableIndexes: writableIndexes,
                readonlyIndexes: readonlyIndexes
            ),
        ]
    }

    /// Remaps the compiled instructions to use the new key indexes after ALT rebuild.
    /// - Parameters:
    ///   - message: The original v0 message.
    ///   - oldAllKeys: The list of all keys before ALT rebuild.
    ///   - newAllKeys: The list of all keys after ALT rebuild.
    /// - Returns: An array of remapped MessageCompiledInstruction objects.
    /// - Throws: If any key or programId cannot be found in the new key list.
    func remapCompiledInstructions(message: MessageV0, oldAllKeys: [PublicKey], newAllKeys: [PublicKey]) throws -> [MessageCompiledInstruction] {
        try message.compiledInstructions.enumerated().map { instrIdx, instr in
            let newAccountKeyIndexes: [UInt8] = instr.accountKeyIndexes.compactMap { oldIdx in
                let keyIndex = Int(oldIdx)
                let origKey = oldAllKeys[keyIndex]
                guard let idx = newAllKeys.firstIndex(of: origKey) else {
                    return nil
                }

                return UInt8(idx)
            }
            let programIdIndex = Int(instr.programIdIndex)
            let origProgramIdKey = oldAllKeys[programIdIndex]

            guard let newProgramIdIndex = newAllKeys.firstIndex(of: origProgramIdKey) else {
                throw Error.keyNotFoundInStaticOrAnyALT
            }

            // Check if this is a ComputeBudget instruction and increase limit
            let instructionData = try patchComputeBudgetIfNeeded(instr, newAllKeys: newAllKeys, newProgramIdIndex: newProgramIdIndex)

            return MessageCompiledInstruction(
                programIdIndex: UInt8(newProgramIdIndex),
                accountKeyIndexes: newAccountKeyIndexes,
                data: instructionData
            )
        }
    }

    /// Increases compute budget limit for ComputeBudget instructions by 20%
    /// - Parameters:
    ///   - instr: Original instruction
    ///   - newAllKeys: New array of keys
    ///   - newProgramIdIndex: New programId index
    /// - Returns: Updated instruction data
    private func patchComputeBudgetIfNeeded(_ instr: MessageCompiledInstruction, newAllKeys: [PublicKey], newProgramIdIndex: Int) throws -> [UInt8] {
        let computeBudgetProgramId = "ComputeBudget111111111111111111111111111111"

        // Check if this is a ComputeBudget setComputeUnitLimit instruction
        guard instr.data.count == 5,
              newProgramIdIndex < newAllKeys.count,
              newAllKeys[newProgramIdIndex].base58EncodedString == computeBudgetProgramId else {
            return instr.data
        }

        let discriminator = instr.data[0]
        let budgetData = Data(instr.data[1 ... 4])

        let currentBudget: UInt32 = budgetData.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self)
        }

        let increasedBudget = UInt32(Int(currentBudget) * 120 / 100) // Increase by 20%
        var increasedBudgetLE = increasedBudget.littleEndian
        let increasedBudgetBytes = Data(bytes: &increasedBudgetLE, count: MemoryLayout<UInt32>.size)

        var newData = [UInt8(discriminator)]
        newData.append(contentsOf: increasedBudgetBytes)

        BSDKLogger.debug("ALT: [REMAP] ComputeBudget increased from \(currentBudget) to \(increasedBudget)")

        return newData
    }

    /// Builds a new MessageV0 object for the rebuilt transaction.
    /// - Parameters:
    ///   - header: The message header.
    ///   - staticAccountKeys: The static account keys for the transaction.
    ///   - recentBlockhash: The recent blockhash for the transaction.
    ///   - compiledInstructions: The remapped compiled instructions.
    ///   - addressTableLookups: The address table lookups for the transaction.
    /// - Returns: The rebuilt MessageV0 object.
    private func buildMessageV0(header: MessageHeader, staticAccountKeys: [PublicKey], recentBlockhash: String, compiledInstructions: [MessageCompiledInstruction], addressTableLookups: [MessageAddressTableLookup]) -> MessageV0 {
        return MessageV0(
            header: header,
            staticAccountKeys: staticAccountKeys,
            recentBlockhash: recentBlockhash,
            compiledInstructions: compiledInstructions,
            addressTableLookups: addressTableLookups
        )
    }

    /// Recalculates the header based on new staticAccountKeys and addressTableLookups.
    /// - Parameters:
    ///   - staticAccountKeys: The static account keys for the transaction.
    ///   - addressTableLookups: The address table lookups for the transaction.
    ///   - originalHeader: The original header of the message.
    /// - Returns: The recalculated header.
    private func recalculateHeader(message: MessageV0, staticAccountKeys: [(PublicKey, Bool)]) -> MessageHeader {
        let newHeader = MessageHeader(
            numRequiredSignatures: 1,
            numReadonlySignedAccounts: 0,
            numReadonlyUnsignedAccounts: staticAccountKeys.filter { $0.1 == false }.count // Program IDs are not counted in header
        )

        return newHeader
    }
}

// MARK: - Constants & Errors

extension SolanaALTMessageV0TransactionSender {
    /// Errors that can occur during ALT transaction building and sending.
    enum Error: UniversalError {
        /// Indicates that a required key was not found in static or any ALT table.
        case keyNotFoundInStaticOrAnyALT

        var errorCode: Int {
            switch self {
            case .keyNotFoundInStaticOrAnyALT:
                return -1
            }
        }
    }
}
