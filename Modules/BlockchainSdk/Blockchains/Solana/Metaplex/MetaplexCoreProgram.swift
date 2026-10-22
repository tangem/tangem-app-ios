//
//  MetaplexCoreProgram.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum MetaplexCoreProgram {
    static let programId = PublicKey(string: "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d")!

    // MARK: - Accounts

    static func asset(from data: Data) throws -> Asset {
        var reader = SolanaBorshReader(data: data)

        guard try reader.readUInt8() == AccountKey.assetV1 else {
            throw MetaplexAccountError.unexpectedAccountKey
        }

        let owner = try reader.readPublicKey()

        let collection: PublicKey?
        switch try reader.readUInt8() {
        case UpdateAuthorityKind.none:
            collection = nil
        case UpdateAuthorityKind.address:
            try reader.skip(byteCount: PublicKey.LENGTH)
            collection = nil
        case UpdateAuthorityKind.collection:
            collection = try reader.readPublicKey()
        default:
            throw MetaplexAccountError.unsupportedLayout
        }

        try reader.skipString()
        try reader.skipString()
        _ = try reader.readOption { try $0.readUInt64() }

        return Asset(
            owner: owner,
            collection: collection,
            transferBlock: try transferBlock(in: data, after: reader)
        )
    }

    static func collectionTransferBlock(data: Data) throws -> TransferBlock? {
        var reader = SolanaBorshReader(data: data)

        guard try reader.readUInt8() == AccountKey.collectionV1 else {
            throw MetaplexAccountError.unexpectedAccountKey
        }

        try reader.skip(byteCount: PublicKey.LENGTH)
        try reader.skipString()
        try reader.skipString()
        try reader.skip(byteCount: 4 + 4)

        return try transferBlock(in: data, after: reader)
    }

    private static func transferBlock(in data: Data, after baseReader: SolanaBorshReader) throws -> TransferBlock? {
        var headerReader = baseReader

        guard !headerReader.isAtEnd else {
            return nil
        }

        guard try headerReader.readUInt8() == AccountKey.pluginHeaderV1 else {
            throw MetaplexAccountError.unsupportedLayout
        }

        var registryReader = SolanaBorshReader(data: data, offset: try headerReader.readOffset())

        guard try registryReader.readUInt8() == AccountKey.pluginRegistryV1 else {
            throw MetaplexAccountError.unsupportedLayout
        }

        var freezePluginOffsets: [Int] = []

        try registryReader.readVector { reader in
            let pluginType = try reader.readUInt8()
            try reader.skipAuthority()
            let offset = try reader.readOffset()

            if PluginType.transferFreezing.contains(pluginType) {
                freezePluginOffsets.append(offset)
            }
        }

        var hasExternalTransferCheck = false

        try registryReader.readVector { reader in
            try reader.skip(byteCount: 1)
            try reader.skipAuthority()

            let checksTransfer = try reader.readOption { reader in
                var checksTransfer = false

                try reader.readVector { reader in
                    if try reader.readUInt8() == HookableLifecycleEvent.transfer {
                        checksTransfer = true
                    }

                    try reader.skip(byteCount: 4)
                }

                return checksTransfer
            }

            if checksTransfer == true {
                hasExternalTransferCheck = true
            }

            try reader.skip(byteCount: 8)
            _ = try reader.readOption { try $0.readUInt64() }
            _ = try reader.readOption { try $0.readUInt64() }
        }

        let isFrozen = try freezePluginOffsets.contains { offset in
            var pluginReader = SolanaBorshReader(data: data, offset: offset)

            guard PluginType.transferFreezing.contains(try pluginReader.readUInt8()) else {
                throw MetaplexAccountError.unsupportedLayout
            }

            return try pluginReader.readBool()
        }

        if isFrozen {
            return .frozen
        }

        return hasExternalTransferCheck ? .externalCheck : nil
    }

    // MARK: - Instructions

    static func transferInstruction(
        asset: PublicKey,
        collection: PublicKey?,
        payer: PublicKey,
        authority: PublicKey,
        newOwner: PublicKey
    ) -> SolanaRawInstruction {
        let accounts: [(PublicKey, isSigner: Bool, isWritable: Bool)] = [
            (asset, false, true),
            (collection ?? programId, false, false),
            (payer, true, true),
            authority == payer ? (programId, false, false) : (authority, true, false),
            (newOwner, false, false),
            (programId, false, false),
            (programId, false, false),
        ]

        return SolanaRawInstruction(
            programId: programId.base58EncodedString,
            accounts: accounts.map { key, isSigner, isWritable in
                SolanaRawInstruction.AccountMeta(address: key.base58EncodedString, isSigner: isSigner, isWritable: isWritable)
            },
            data: Data([Discriminator.transferV1, OptionTag.none])
        )
    }
}

// MARK: - Nested types

extension MetaplexCoreProgram {
    struct Asset: Equatable {
        let owner: PublicKey
        let collection: PublicKey?
        let transferBlock: TransferBlock?
    }

    enum TransferBlock: Equatable {
        case frozen
        case externalCheck
    }

    private enum AccountKey {
        static let assetV1: UInt8 = 1
        static let pluginHeaderV1: UInt8 = 3
        static let pluginRegistryV1: UInt8 = 4
        static let collectionV1: UInt8 = 5
    }

    private enum UpdateAuthorityKind {
        static let none: UInt8 = 0
        static let address: UInt8 = 1
        static let collection: UInt8 = 2
    }

    fileprivate enum AuthorityKind {
        static let address: UInt8 = 3
    }

    private enum HookableLifecycleEvent {
        static let transfer: UInt8 = 1
    }

    private enum PluginType {
        static let freezeDelegate: UInt8 = 1
        static let permanentFreezeDelegate: UInt8 = 5
        static let transferFreezing: Set<UInt8> = [freezeDelegate, permanentFreezeDelegate]
    }

    private enum Discriminator {
        static let transferV1: UInt8 = 14
    }

    private enum OptionTag {
        static let none: UInt8 = 0
    }
}

private extension SolanaBorshReader {
    mutating func readOffset() throws -> Int {
        guard let offset = Int(exactly: try readUInt64()) else {
            throw MetaplexAccountError.unsupportedLayout
        }

        return offset
    }

    mutating func skipAuthority() throws {
        if try readUInt8() == MetaplexCoreProgram.AuthorityKind.address {
            try skip(byteCount: PublicKey.LENGTH)
        }
    }
}
