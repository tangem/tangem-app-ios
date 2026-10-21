//
//  SolanaNFTTransferBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

protocol SolanaRawAccountProvider {
    func rawAccountInfo(address: String) async throws -> SolanaRawAccount?
}

extension SolanaNetworkService: SolanaRawAccountProvider {}

struct SolanaNFTTransferBuilder {
    private let accountProvider: SolanaRawAccountProvider

    init(accountProvider: SolanaRawAccountProvider) {
        self.accountProvider = accountProvider
    }

    func route(
        assetAddress: String,
        owner: String,
        destination: String,
        payer: String
    ) async throws -> SolanaNFTTransferRoute {
        let asset = try publicKey(assetAddress)
        let owner = try publicKey(owner)
        let destination = try publicKey(destination)
        let payer = try publicKey(payer)

        guard let assetAccount = try await accountProvider.rawAccountInfo(address: assetAddress) else {
            throw SolanaNFTTransferError.assetNotFound
        }

        switch assetAccount.owner {
        case MetaplexCoreProgram.programId.base58EncodedString:
            return .program(try await coreTransfer(
                asset: asset,
                assetData: assetAccount.data,
                owner: owner,
                destination: destination,
                payer: payer
            ))

        case PublicKey.tokenProgramId.base58EncodedString:
            let metadataAddress = try MetaplexTokenMetadataProgram.metadataAddress(mint: asset)

            guard
                let metadataAccount = try await accountProvider.rawAccountInfo(address: metadataAddress.base58EncodedString),
                metadataAccount.owner == MetaplexTokenMetadataProgram.programId.base58EncodedString
            else {
                return .splToken
            }

            let metadata = try MetaplexTokenMetadataProgram.metadata(from: metadataAccount.data)

            guard metadata.isProgrammable else {
                return .splToken
            }

            return .program(try await programmableTransfer(
                mint: asset,
                ruleSet: metadata.ruleSet,
                owner: owner,
                destination: destination,
                payer: payer
            ))

        case PublicKey.token2022ProgramId.base58EncodedString:
            return .splToken

        default:
            throw SolanaNFTTransferError.unsupportedAsset
        }
    }

    private func coreTransfer(
        asset: PublicKey,
        assetData: Data,
        owner: PublicKey,
        destination: PublicKey,
        payer: PublicKey
    ) async throws -> SolanaNFTTransferPlan {
        guard destination != asset else {
            throw SolanaNFTTransferError.invalidDestination
        }

        let parsedAsset = try MetaplexCoreProgram.asset(from: assetData)

        guard parsedAsset.owner == owner else {
            throw SolanaNFTTransferError.notOwner
        }

        try Self.validate(parsedAsset.transferBlock)

        if let collection = parsedAsset.collection {
            guard
                let collectionAccount = try await accountProvider.rawAccountInfo(address: collection.base58EncodedString),
                collectionAccount.owner == MetaplexCoreProgram.programId.base58EncodedString
            else {
                throw SolanaNFTTransferError.unsupportedAsset
            }

            try Self.validate(MetaplexCoreProgram.collectionTransferBlock(data: collectionAccount.data))
        }

        return SolanaNFTTransferPlan(
            instructions: [
                MetaplexCoreProgram.transferInstruction(
                    asset: asset,
                    collection: parsedAsset.collection,
                    payer: payer,
                    authority: owner,
                    newOwner: destination
                ),
            ],
            computeUnitLimit: Constants.coreComputeUnitLimit,
            createdAccountSpaces: []
        )
    }

    private func programmableTransfer(
        mint: PublicKey,
        ruleSet: PublicKey?,
        owner: PublicKey,
        destination: PublicKey,
        payer: PublicKey
    ) async throws -> SolanaNFTTransferPlan {
        let token = try MetaplexTokenMetadataProgram.associatedTokenAddress(owner: owner, mint: mint)
        let ownerTokenRecord = try MetaplexTokenMetadataProgram.tokenRecordAddress(mint: mint, token: token)
        let destinationToken = try MetaplexTokenMetadataProgram.associatedTokenAddress(owner: destination, mint: mint)
        let destinationTokenRecord = try MetaplexTokenMetadataProgram.tokenRecordAddress(mint: mint, token: destinationToken)

        async let ownerTokenRecordAccount = accountProvider.rawAccountInfo(address: ownerTokenRecord.base58EncodedString)
        async let destinationTokenAccount = accountProvider.rawAccountInfo(address: destinationToken.base58EncodedString)
        async let destinationTokenRecordAccount = accountProvider.rawAccountInfo(address: destinationTokenRecord.base58EncodedString)

        guard let ownerTokenRecordData = try await ownerTokenRecordAccount?.data else {
            throw SolanaNFTTransferError.notOwner
        }

        guard try MetaplexTokenMetadataProgram.tokenRecordState(from: ownerTokenRecordData) == .unlocked else {
            throw SolanaNFTTransferError.locked
        }

        let createdAccountSpaces = [
            try await destinationTokenAccount == nil ? MetaplexTokenMetadataProgram.tokenAccountSpace : nil,
            try await destinationTokenRecordAccount == nil ? MetaplexTokenMetadataProgram.tokenRecordSpace : nil,
        ].compactMap { $0 }

        return SolanaNFTTransferPlan(
            instructions: [
                try MetaplexTokenMetadataProgram.transferInstruction(
                    mint: mint,
                    owner: owner,
                    destinationOwner: destination,
                    authority: owner,
                    payer: payer,
                    ruleSet: ruleSet
                ),
            ],
            computeUnitLimit: Constants.programmableComputeUnitLimit,
            createdAccountSpaces: createdAccountSpaces
        )
    }

    private static func validate(_ transferBlock: MetaplexCoreProgram.TransferBlock?) throws {
        switch transferBlock {
        case .none:
            return
        case .frozen:
            throw SolanaNFTTransferError.frozen
        case .externalCheck:
            throw SolanaNFTTransferError.unsupportedAsset
        }
    }

    private func publicKey(_ address: String) throws -> PublicKey {
        guard let key = PublicKey(string: address), key.bytes.count == PublicKey.LENGTH else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        return key
    }
}

// MARK: - Nested types

enum SolanaNFTTransferRoute {
    case splToken
    case program(SolanaNFTTransferPlan)
}

struct SolanaNFTTransferPlan {
    let instructions: [SolanaRawInstruction]
    let computeUnitLimit: UInt32
    let createdAccountSpaces: [UInt64]
}

public enum SolanaNFTTransferError: Error, Equatable {
    case assetNotFound
    case unsupportedAsset
    case notOwner
    case frozen
    case locked
    case invalidDestination
}

private extension SolanaNFTTransferBuilder {
    enum Constants {
        static let coreComputeUnitLimit: UInt32 = 50_000
        static let programmableComputeUnitLimit: UInt32 = 200_000
    }
}
