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

    /// Splits account keys into static (payer + signers + program IDs) and ALT candidates.
    /// - Static: payer (writable), signers (writable or readonly per header), program IDs
    /// - ALT: everything else, ordered writable-first then readonly
    private func splitStaticAccountKeysForSeparation(
        _ inputStaticAccountKeys: [PublicKey],
        header: MessageHeader,
        compiledInstructions: [MessageCompiledInstruction],
        isAccountWritable: (Int) -> Bool
    ) -> SolanaALTSplitResult {
        guard let payer = inputStaticAccountKeys.first else {
            return ([], [])
        }

        var signerKeys = Set<PublicKey>()
        for i in 0 ..< Int(header.numRequiredSignatures) {
            signerKeys.insert(inputStaticAccountKeys[i])
        }

        var programIdKeys = Set<PublicKey>()
        for instr in compiledInstructions {
            let programIdIndex = Int(instr.programIdIndex)
            if programIdIndex < inputStaticAccountKeys.count {
                programIdKeys.insert(inputStaticAccountKeys[programIdIndex])
            }
        }

        var staticKeySet = Set<PublicKey>()
        staticKeySet.insert(payer)
        staticKeySet.formUnion(signerKeys)
        staticKeySet.formUnion(programIdKeys)

        var staticAccountKeys: [(PublicKey, Bool)] = []
        var altCandidatesWritable: [PublicKey] = []
        var altCandidatesReadonly: [PublicKey] = []

        for (idx, key) in inputStaticAccountKeys.enumerated() {
            guard !staticKeySet.contains(key) else {
                staticAccountKeys.append((key, isAccountWritable(idx)))
                continue
            }

            if isAccountWritable(idx) {
                altCandidatesWritable.append(key)
            } else {
                altCandidatesReadonly.append(key)
            }
        }

        if let payerIdx = staticAccountKeys.map({ $0.0 }).firstIndex(of: payer), payerIdx != 0 {
            staticAccountKeys.remove(at: payerIdx)
            staticAccountKeys.insert((payer, true), at: 0)
        }

        return (staticAccountKeys, altCandidatesWritable + altCandidatesReadonly)
    }
}
