//
//  CollectiblesBuybackTransactionVerifier.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SolanaSwift

struct CollectiblesBuybackTransactionVerifier {
    // MARK: - Properties

    private let owner: Data
    private let usdcMint: Data
    private let payoutAccount: String
    private let terms: CollectiblesBuybackTerms

    private var ownerAddress: String {
        owner.base58EncodedString
    }

    // MARK: - Init

    init(owner: Data, usdcMint: Data, payoutAccount: String, terms: CollectiblesBuybackTerms) {
        self.owner = owner
        self.usdcMint = usdcMint
        self.payoutAccount = payoutAccount
        self.terms = terms
    }

    // MARK: - Methods

    func verify(_ transaction: CollectiblesPreparedTransaction) throws {
        try verifySigners(of: transaction)

        var seenKinds: Set<InstructionKind> = []

        for (index, instruction) in transaction.instructions.enumerated() {
            let context = Context(transaction: transaction, instruction: instruction, index: index)
            let kind = try classify(context)

            guard seenKinds.insert(kind).inserted else {
                throw VerificationError.repeatedInstruction(index: index)
            }
        }

        guard seenKinds.isSuperset(of: [.assetTransfer, .payout]) else {
            throw VerificationError.missingInstruction
        }
    }
}

// MARK: - Private logic

private extension CollectiblesBuybackTransactionVerifier {
    func verifySigners(of transaction: CollectiblesPreparedTransaction) throws {
        guard let ownerIndex = transaction.signers.firstIndex(of: owner) else {
            throw VerificationError.ownerNotSigner
        }

        guard !transaction.isWritable(ownerIndex) else {
            throw VerificationError.ownerWritable
        }

        let cosignerSignatures = transaction.signatures.indices
            .filter { $0 != ownerIndex }
            .map { transaction.signatures[$0] }

        guard !cosignerSignatures.contains(Constants.emptySignature) else {
            throw VerificationError.cosignerSignatureMissing
        }
    }

    func classify(_ context: Context) throws -> InstructionKind {
        switch context.program {
        case Constants.computeBudgetProgramId:
            return try computeBudgetKind(of: context)
        case Constants.mplCoreProgramId:
            try verifyAssetTransfer(context)
            return .assetTransfer
        case Constants.associatedTokenProgramId:
            try verifyPayoutAccountCreation(context)
            return .payoutAccountCreation
        case Constants.tokenProgramId:
            try verifyPayout(context)
            return .payout
        case Constants.memoProgramId:
            guard context.instruction.accountIndices.isEmpty else {
                throw context.unexpected
            }

            return .memo
        default:
            throw context.unexpected
        }
    }

    func computeBudgetKind(of context: Context) throws -> InstructionKind {
        let data = context.instruction.data

        guard context.instruction.accountIndices.isEmpty, let tag = data.first else {
            throw context.unexpected
        }

        switch (tag, data.count) {
        case (Constants.setComputeUnitLimitTag, Constants.setComputeUnitLimitLength):
            return .computeUnitLimit
        case (Constants.setComputeUnitPriceTag, Constants.setComputeUnitPriceLength):
            return .computeUnitPrice
        default:
            throw context.unexpected
        }
    }

    func verifyAssetTransfer(_ context: Context) throws {
        guard context.instruction.data == Constants.assetTransferData,
              context.instruction.accountIndices.count == Constants.assetTransferAccountCount,
              try context.account(at: Constants.assetTransferAuthoritySlot) == ownerAddress else {
            throw context.unexpected
        }

        guard try context.account(at: Constants.assetTransferAssetSlot) == terms.nftAddress else {
            throw VerificationError.foreignAsset
        }
    }

    func verifyPayoutAccountCreation(_ context: Context) throws {
        guard context.instruction.data == Constants.createIdempotentData,
              context.instruction.accountIndices.count == Constants.createAccountCount,
              try context.account(at: Constants.createTokenProgramSlot) == Constants.tokenProgramId else {
            throw context.unexpected
        }

        guard try context.account(at: Constants.createAccountSlot) == payoutAccount,
              try context.account(at: Constants.createMintSlot) == usdcMint.base58EncodedString else {
            throw VerificationError.foreignPayout
        }
    }

    func verifyPayout(_ context: Context) throws {
        let data = context.instruction.data

        guard data.first == Constants.transferCheckedTag,
              data.count == Constants.transferCheckedLength,
              context.instruction.accountIndices.count == Constants.transferCheckedAccountCount,
              try context.account(at: Constants.transferSourceSlot) != payoutAccount,
              try context.account(at: Constants.transferAuthoritySlot) != ownerAddress else {
            throw context.unexpected
        }

        guard try context.account(at: Constants.transferMintSlot) == usdcMint.base58EncodedString,
              try context.account(at: Constants.transferDestinationSlot) == payoutAccount else {
            throw VerificationError.foreignPayout
        }

        guard Self.amount(of: data) >= terms.minimumPayoutInBaseUnits else {
            throw VerificationError.payoutBelowAgreedPrice
        }
    }

    static func amount(of transferCheckedData: Data) -> UInt64 {
        transferCheckedData
            .dropFirst()
            .prefix(MemoryLayout<UInt64>.size)
            .reversed()
            .reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
    }
}

// MARK: - Context

private extension CollectiblesBuybackTransactionVerifier {
    struct Context {
        let transaction: CollectiblesPreparedTransaction
        let instruction: CollectiblesPreparedTransaction.Instruction
        let index: Int

        var program: String {
            transaction.accountKeys[instruction.programIndex].base58EncodedString
        }

        var unexpected: VerificationError {
            .unexpectedInstruction(index: index)
        }

        func account(at slot: Int) throws -> String {
            guard instruction.accountIndices.indices.contains(slot) else {
                throw unexpected
            }

            return transaction.accountKeys[instruction.accountIndices[slot]].base58EncodedString
        }
    }

    enum InstructionKind {
        case computeUnitLimit
        case computeUnitPrice
        case assetTransfer
        case payoutAccountCreation
        case payout
        case memo
    }
}

// MARK: - Error

extension CollectiblesBuybackTransactionVerifier {
    enum VerificationError: Error, Equatable {
        case ownerNotSigner
        case ownerWritable
        case cosignerSignatureMissing
        case unexpectedInstruction(index: Int)
        case repeatedInstruction(index: Int)
        case missingInstruction
        case foreignAsset
        case foreignPayout
        case payoutBelowAgreedPrice
    }
}

// MARK: - Constants

private extension CollectiblesBuybackTransactionVerifier {
    enum Constants {
        static let emptySignature = Data(repeating: 0, count: 64)

        static let computeBudgetProgramId = "ComputeBudget111111111111111111111111111111"
        static let mplCoreProgramId = "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d"
        static let associatedTokenProgramId = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
        static let tokenProgramId = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
        static let memoProgramId = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"

        static let setComputeUnitLimitTag: UInt8 = 2
        static let setComputeUnitLimitLength = 5
        static let setComputeUnitPriceTag: UInt8 = 3
        static let setComputeUnitPriceLength = 9

        static let assetTransferData = Data([14, 0])
        static let assetTransferAccountCount = 7
        static let assetTransferAssetSlot = 0
        static let assetTransferAuthoritySlot = 3

        static let createIdempotentData = Data([1])
        static let createAccountCount = 6
        static let createAccountSlot = 1
        static let createMintSlot = 3
        static let createTokenProgramSlot = 5

        static let transferCheckedTag: UInt8 = 12
        static let transferCheckedLength = 10
        static let transferCheckedAccountCount = 4
        static let transferSourceSlot = 0
        static let transferMintSlot = 1
        static let transferDestinationSlot = 2
        static let transferAuthoritySlot = 3
    }
}
