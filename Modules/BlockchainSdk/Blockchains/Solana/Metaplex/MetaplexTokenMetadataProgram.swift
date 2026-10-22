//
//  MetaplexTokenMetadataProgram.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum MetaplexTokenMetadataProgram {
    static let programId = PublicKey(string: "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s")!
    static let authorizationRulesProgramId = PublicKey(string: "auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg")!
    static let sysvarInstructionsId = PublicKey(string: "Sysvar1nstructions1111111111111111111111111")!
    static let associatedTokenProgramId = PublicKey(string: "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")!

    static let tokenRecordSpace: UInt64 = 80
    static let tokenAccountSpace: UInt64 = 165

    // MARK: - Addresses

    static func metadataAddress(mint: PublicKey) throws -> PublicKey {
        try programAddress(seeds: [mint.data])
    }

    static func editionAddress(mint: PublicKey) throws -> PublicKey {
        try programAddress(seeds: [mint.data, Data("edition".utf8)])
    }

    static func tokenRecordAddress(mint: PublicKey, token: PublicKey) throws -> PublicKey {
        try programAddress(seeds: [mint.data, Data("token_record".utf8), token.data])
    }

    private static func programAddress(seeds: [Data]) throws -> PublicKey {
        try PublicKey.findProgramAddress(
            seeds: [Data("metadata".utf8), programId.data] + seeds,
            programId: programId
        ).get().0
    }

    // MARK: - Accounts

    static func metadata(from data: Data) throws -> Metadata {
        var reader = SolanaBorshReader(data: data)

        guard try reader.readUInt8() == AccountKey.metadataV1 else {
            throw MetaplexAccountError.unexpectedAccountKey
        }

        try reader.skip(byteCount: PublicKey.LENGTH * 2)
        try reader.skipString()
        try reader.skipString()
        try reader.skipString()
        try reader.skip(byteCount: 2)
        _ = try reader.readOption { reader in
            try reader.readVector { reader in
                try reader.skip(byteCount: PublicKey.LENGTH + 2)
            }
        }
        try reader.skip(byteCount: 2)

        _ = try? reader.readOption { try $0.readUInt8() }
        let rawTokenStandard = (try? reader.readTokenStandardCollectionAndUses()) ?? nil
        _ = try? reader.readOption { try $0.skip(byteCount: 1 + 8) }
        let ruleSet = (try? reader.readProgrammableConfigRuleSet()) ?? nil

        return Metadata(tokenStandard: rawTokenStandard.flatMap(TokenStandard.init(rawValue:)), ruleSet: ruleSet)
    }

    static func tokenRecordState(from data: Data) throws -> TokenState {
        var reader = SolanaBorshReader(data: data)

        guard try reader.readUInt8() == AccountKey.tokenRecord else {
            throw MetaplexAccountError.unexpectedAccountKey
        }

        try reader.skip(byteCount: 1)

        guard let state = TokenState(rawValue: try reader.readUInt8()) else {
            throw MetaplexAccountError.unsupportedLayout
        }

        return state
    }

    // MARK: - Instructions

    static func transferInstruction(
        mint: PublicKey,
        owner: PublicKey,
        destinationOwner: PublicKey,
        authority: PublicKey,
        payer: PublicKey,
        ruleSet: PublicKey?
    ) throws -> SolanaRawInstruction {
        let token = try associatedTokenAddress(owner: owner, mint: mint)
        let destination = try associatedTokenAddress(owner: destinationOwner, mint: mint)

        let accounts: [(PublicKey, isSigner: Bool, isWritable: Bool)] = [
            (token, false, true),
            (owner, false, false),
            (destination, false, true),
            (destinationOwner, false, false),
            (mint, false, false),
            (try metadataAddress(mint: mint), false, true),
            (try editionAddress(mint: mint), false, false),
            (try tokenRecordAddress(mint: mint, token: token), false, true),
            (try tokenRecordAddress(mint: mint, token: destination), false, true),
            (authority, true, false),
            (payer, true, true),
            (PublicKey.programId, false, false),
            (sysvarInstructionsId, false, false),
            (PublicKey.tokenProgramId, false, false),
            (associatedTokenProgramId, false, false),
            (ruleSet == nil ? programId : authorizationRulesProgramId, false, false),
            (ruleSet ?? programId, false, false),
        ]

        return SolanaRawInstruction(
            programId: programId.base58EncodedString,
            accounts: accounts.map { key, isSigner, isWritable in
                SolanaRawInstruction.AccountMeta(address: key.base58EncodedString, isSigner: isSigner, isWritable: isWritable)
            },
            data: transferData(amount: 1)
        )
    }

    static func associatedTokenAddress(owner: PublicKey, mint: PublicKey) throws -> PublicKey {
        try PublicKey.associatedTokenAddress(
            walletAddress: owner,
            tokenMintAddress: mint,
            tokenProgramId: .tokenProgramId
        ).get()
    }

    private static func transferData(amount: UInt64) -> Data {
        Data([Discriminator.transfer, TransferArgsVersion.v1])
            + withUnsafeBytes(of: amount.littleEndian) { Data($0) }
            + Data([OptionTag.none])
    }
}

// MARK: - Nested types

extension MetaplexTokenMetadataProgram {
    struct Metadata: Equatable {
        let tokenStandard: TokenStandard?
        let ruleSet: PublicKey?

        var isProgrammable: Bool {
            switch tokenStandard {
            case .programmableNonFungible, .programmableNonFungibleEdition: true
            case .nonFungible, .fungibleAsset, .fungible, .nonFungibleEdition, .none: false
            }
        }
    }

    enum TokenStandard: UInt8 {
        case nonFungible
        case fungibleAsset
        case fungible
        case nonFungibleEdition
        case programmableNonFungible
        case programmableNonFungibleEdition
    }

    enum TokenState: UInt8 {
        case unlocked
        case locked
        case listed
    }

    private enum AccountKey {
        static let metadataV1: UInt8 = 4
        static let tokenRecord: UInt8 = 11
    }

    private enum Discriminator {
        static let transfer: UInt8 = 49
    }

    private enum TransferArgsVersion {
        static let v1: UInt8 = 0
    }

    fileprivate enum ProgrammableConfigVersion {
        static let v1: UInt8 = 0
    }

    private enum OptionTag {
        static let none: UInt8 = 0
    }
}

enum MetaplexAccountError: Error, Equatable {
    case unexpectedAccountKey
    case unsupportedLayout
}

private extension SolanaBorshReader {
    mutating func readTokenStandardCollectionAndUses() throws -> UInt8? {
        let tokenStandard = try readOption { try $0.readUInt8() }
        _ = try readOption { try $0.skip(byteCount: 1 + PublicKey.LENGTH) }
        _ = try readOption { try $0.skip(byteCount: 1 + 8 + 8) }
        return tokenStandard
    }

    mutating func readProgrammableConfigRuleSet() throws -> PublicKey? {
        let ruleSet = try readOption { reader in
            guard try reader.readUInt8() == MetaplexTokenMetadataProgram.ProgrammableConfigVersion.v1 else {
                throw MetaplexAccountError.unsupportedLayout
            }

            return try reader.readOption { try $0.readPublicKey() }
        }

        return ruleSet ?? nil
    }
}
