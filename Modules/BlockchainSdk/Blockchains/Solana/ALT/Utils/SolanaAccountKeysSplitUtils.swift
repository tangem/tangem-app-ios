//
//  SolanaAccountKeysSplitUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

typealias SolanaALTSplitResult = (staticAccountKeys: [(PublicKey, Bool)], altCandidates: [PublicKey])

protocol SolanaAccountKeysSplitProvider {
    /// Splits legacy accountKeys into static and alt for v0 according to the following rules:
    /// - static: payer, all signers, all programIds
    /// - alt: all others
    ///   - legacyAccountKeys: array of keys from legacyMessage.accountKeys
    ///   - payer: feePayer
    ///   - instructions: array of legacy instructions (used to find signers and programIds)
    ///   - isAccountSigner: function to determine if an index is a signer
    /// - Returns: (staticAccountKeys, altKeys)
    func splitStaticAccountKeys(legacy message: LegacyMessage) -> SolanaALTSplitResult

    /// Splits v0 staticAccountKeys into "important" (payer, signers, programIds) and "others" (candidates for ALT), similar to legacy:
    /// - static: payer, all signers, all programIds
    /// - alt: all others
    ///   - message: MessageV0
    /// - Returns: (staticAccountKeys, altCandidates)
    func splitStaticAccountKeys(v0 message: MessageV0) -> SolanaALTSplitResult
}

struct SolanaAccountKeysSplitUtils: SolanaAccountKeysSplitProvider {
    func splitStaticAccountKeys(legacy message: LegacyMessage) -> SolanaALTSplitResult {
        let compiledInstructions = message.instructions.map {
            MessageCompiledInstruction(
                programIdIndex: $0.programIdIndex,
                accountKeyIndexes: $0.keyIndices,
                data: $0.data
            )
        }

        return splitStaticAccountKeysForSeparation(
            message.staticAccountKeys,
            header: message.header,
            compiledInstructions: compiledInstructions,
            isAccountWritable: message.isAccountWritable(index:)
        )
    }

    func splitStaticAccountKeys(v0 message: MessageV0) -> SolanaALTSplitResult {
        splitStaticAccountKeysForSeparation(
            message.staticAccountKeys,
            header: message.header,
            compiledInstructions: message.compiledInstructions,
            isAccountWritable: message.isAccountWritable(index:)
        )
    }

    // MARK: - Private Implementation

    private func splitStaticAccountKeysForSeparation(
        _ inputStaticAccountKeys: [PublicKey],
        header: MessageHeader,
        compiledInstructions: [MessageCompiledInstruction],
        isAccountWritable: (Int) -> Bool
    ) -> SolanaALTSplitResult {
        guard let payer = inputStaticAccountKeys.first else {
            return ([], [])
        }
        var staticKeySet = Set<PublicKey>()
        staticKeySet.insert(payer)
        // Add signers
        for i in 0 ..< Int(header.numRequiredSignatures) {
            staticKeySet.insert(inputStaticAccountKeys[i])
        }
        // Add programIds from all instructions
        for instr in compiledInstructions {
            let programIdIndex = Int(instr.programIdIndex)
            if programIdIndex < inputStaticAccountKeys.count {
                staticKeySet.insert(inputStaticAccountKeys[programIdIndex])
            }
        }
        // Explicitly add system programs (Memo, ComputeBudget, SystemProgram, etc.)
        for key in inputStaticAccountKeys {
            if SolanaAccountKeysSplitUtils.alwaysStatic.contains(key.base58EncodedString) {
                staticKeySet.insert(key)
            }
        }

        var staticAccountKeys: [(PublicKey, Bool)] = []
        var altCandidatesWritable: [PublicKey] = []
        var altCandidatesReadonly: [PublicKey] = []
        for (idx, key) in inputStaticAccountKeys.enumerated() {
            let isWritable = isAccountWritable(idx)

            guard !staticKeySet.contains(key) else {
                staticAccountKeys.append((key, isWritable))
                continue
            }

            if isWritable {
                altCandidatesWritable.append(key)
            } else {
                altCandidatesReadonly.append(key)
            }
        }
        // payer is always first
        if let payerIdx = staticAccountKeys.map({ $0.0 }).firstIndex(of: payer), payerIdx != 0 {
            staticAccountKeys.remove(at: payerIdx)
            staticAccountKeys.insert((payer, true), at: 0)
        }
        return (staticAccountKeys, altCandidatesWritable + altCandidatesReadonly)
    }
}

extension SolanaAccountKeysSplitUtils {
    /// System programs that must always be included only in staticAccountKeys
    static let alwaysStatic: Set<String> = [
        // System
        "11111111111111111111111111111111",
        // Memo
        "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr",
        // ComputeBudget
        "ComputeBudget111111111111111111111111111111",
        // Wrapped SOL
        "So11111111111111111111111111111111111111112",
        // SPL Token
        "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
        // Associated Token
        "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
        // Token2022
        "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
        // Address Lookup Table
        "AddressLookupTab1e1111111111111111111111111",
        // (add others if used)
    ]
}
