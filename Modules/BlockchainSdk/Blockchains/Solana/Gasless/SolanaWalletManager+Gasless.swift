//
//  SolanaWalletManager+Gasless.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import TangemFoundation

extension SolanaWalletManager: SolanaGaslessTransactionBuilder {
    func buildGaslessTransaction(
        _ transaction: Transaction,
        feePayer: String,
        signer: TransactionSigner
    ) async throws -> SolanaGaslessTransaction {
        guard let feeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            throw SolanaGaslessError.missingFeeParameters
        }

        let feePayerKey = try gaslessFeePayerKey(feePayer)
        let instructions = try await gaslessTransferInstructions(transaction: transaction, feeParameters: feeParameters)
        let latestBlockhash = try await networkService.getLatestBlockhashWithHeight()

        let solanaTransaction = SolanaSwift.Transaction.empty(feePayer: feePayerKey, recentBlockhash: latestBlockhash.blockhash)
        for instruction in instructions {
            _ = solanaTransaction.add(instruction)
        }

        let message = try solanaTransaction.serializeMessage().get()
        guard let signatureSlotCount = message.first.map({ Int($0) }) else {
            throw SolanaGaslessError.malformedTransaction
        }

        let unsignedTransaction = Data.encodeLength(signatureSlotCount)
            + Data(repeating: 0, count: signatureSlotCount * GaslessConstants.signatureLength)
            + message

        return try await signGaslessTransaction(unsignedTransaction, latestBlockhash: latestBlockhash, signer: signer)
    }

    func buildGaslessTransaction(
        compiledTransaction: Data,
        feePayer: String,
        signer: TransactionSigner
    ) async throws -> SolanaGaslessTransaction {
        let feePayerKey = try gaslessFeePayerKey(feePayer)
        let latestBlockhash = try await networkService.getLatestBlockhashWithHeight()

        let transactionHelper = SolanaTransactionHelper()

        let refreshedTransaction = try transactionHelper.replaceRecentBlockhash(
            Data(Base58.decode(latestBlockhash.blockhash)),
            in: compiledTransaction
        )

        let unsignedTransaction = try transactionHelper.injectFeePayer(
            Data(feePayerKey.bytes),
            walletPublicKey: wallet.publicKey.blockchainKey,
            into: refreshedTransaction
        )

        return try await signGaslessTransaction(unsignedTransaction, latestBlockhash: latestBlockhash, signer: signer)
    }
}

// MARK: - Private

private extension SolanaWalletManager {
    func signGaslessTransaction(
        _ unsignedTransaction: Data,
        latestBlockhash: SolanaLatestBlockhash,
        signer: TransactionSigner
    ) async throws -> SolanaGaslessTransaction {
        let helper = SolanaTransactionHelper()
        let message = try helper.removeSignaturesPlaceholders(from: unsignedTransaction).transaction

        let solanaSigner = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        let signature = try await solanaSigner.sign(message: message)

        let signedTransaction = try helper.putSignature(
            signature,
            publicKey: wallet.publicKey.blockchainKey,
            transaction: unsignedTransaction
        )

        return SolanaGaslessTransaction(
            serialized: signedTransaction,
            lastValidBlockHeight: latestBlockhash.lastValidBlockHeight
        )
    }

    func gaslessTransferInstructions(
        transaction: Transaction,
        feeParameters: SolanaFeeParameters
    ) async throws -> [TransactionInstruction] {
        let owner = try gaslessPublicKey(transaction.sourceAddress)
        let computeBudgetInstructions = try SolanaComputeBudgetInstruction.instructions(
            computeUnitLimit: feeParameters.computeUnitLimit,
            computeUnitPrice: feeParameters.computeUnitPrice
        )
        .map { try $0.transactionInstruction() }

        switch transaction.amount.type {
        case .coin:
            let destination = try gaslessPublicKey(transaction.destinationAddress)
            let lamports = (transaction.amount.value * wallet.blockchain.decimalValue).rounded().uint64Value

            return computeBudgetInstructions + [
                SystemProgram.transferInstruction(from: owner, to: destination, lamports: lamports),
            ]

        case .token(let token) where token.metadata.kind == .fungible:
            let tokenProgramId = try await networkService.tokenProgramId(contractAddress: token.contractAddress).async()
            let amount = try await makeTokenTransferAmountPublisher(
                tokenProgramId: tokenProgramId,
                amount: transaction.amount.value,
                token: token
            )
            .async()

            guard let sourceTokenAddress = associatedTokenAddress(
                accountAddress: transaction.sourceAddress,
                mintAddress: token.contractAddress,
                tokenProgramId: tokenProgramId
            ) else {
                throw BlockchainSdkError.failedToConvertPublicKey
            }

            let mint = try gaslessPublicKey(token.contractAddress)
            let destination = try await networkService.splTokenDestination(
                mintAddress: token.contractAddress,
                tokenProgramId: tokenProgramId,
                destinationAddress: transaction.destinationAddress
            )

            var instructions = computeBudgetInstructions

            if destination.isUnregisteredAsocciatedToken {
                instructions.append(
                    createAssociatedTokenAccountInstruction(
                        tokenProgramId: tokenProgramId,
                        mint: mint,
                        associatedAccount: destination.destination,
                        owner: try gaslessPublicKey(transaction.destinationAddress),
                        payer: owner
                    )
                )
            }

            instructions.append(
                transferCheckedInstruction(
                    tokenProgramId: tokenProgramId,
                    source: try gaslessPublicKey(sourceTokenAddress),
                    mint: mint,
                    destination: destination.destination,
                    owner: owner,
                    amount: amount,
                    decimals: UInt8(token.decimalCount)
                )
            )

            return instructions

        case .token, .reserve, .feeResource:
            throw SolanaGaslessError.unsupportedAmountType
        }
    }

    func transferCheckedInstruction(
        tokenProgramId: PublicKey,
        source: PublicKey,
        mint: PublicKey,
        destination: PublicKey,
        owner: PublicKey,
        amount: UInt64,
        decimals: UInt8
    ) -> TransactionInstruction {
        TransactionInstruction(
            keys: [
                .init(publicKey: source, isSigner: false, isWritable: true),
                .init(publicKey: mint, isSigner: false, isWritable: false),
                .init(publicKey: destination, isSigner: false, isWritable: true),
                .init(publicKey: owner, isSigner: true, isWritable: false),
            ],
            programId: tokenProgramId,
            data: [GaslessConstants.transferCheckedInstructionIndex] + withUnsafeBytes(of: amount.littleEndian, Array.init) + [decimals]
        )
    }

    func createAssociatedTokenAccountInstruction(
        tokenProgramId: PublicKey,
        mint: PublicKey,
        associatedAccount: PublicKey,
        owner: PublicKey,
        payer: PublicKey
    ) -> TransactionInstruction {
        TransactionInstruction(
            keys: [
                .init(publicKey: payer, isSigner: true, isWritable: true),
                .init(publicKey: associatedAccount, isSigner: false, isWritable: true),
                .init(publicKey: owner, isSigner: false, isWritable: false),
                .init(publicKey: mint, isSigner: false, isWritable: false),
                .init(publicKey: .programId, isSigner: false, isWritable: false),
                .init(publicKey: tokenProgramId, isSigner: false, isWritable: false),
                .init(publicKey: .sysvarRent, isSigner: false, isWritable: false),
            ],
            programId: .splAssociatedTokenAccountProgramId,
            data: []
        )
    }

    func gaslessFeePayerKey(_ address: String) throws -> PublicKey {
        guard let key = PublicKey(string: address), key.bytes.count == PublicKey.LENGTH else {
            throw SolanaGaslessError.invalidFeePayer
        }

        return key
    }

    func gaslessPublicKey(_ address: String) throws -> PublicKey {
        guard let key = PublicKey(string: address), key.bytes.count == PublicKey.LENGTH else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        return key
    }
}

private extension SolanaWalletManager {
    enum GaslessConstants {
        static let signatureLength = 64
        static let transferCheckedInstructionIndex: UInt8 = 12
    }
}
