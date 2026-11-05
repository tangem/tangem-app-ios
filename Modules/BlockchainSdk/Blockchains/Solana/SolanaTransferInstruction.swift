//
//  SolanaTransferInstruction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum SolanaTransferInstruction {
    static func systemTransfer(from source: PublicKey, to destination: PublicKey, lamports: UInt64) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: PublicKey.programId.base58EncodedString,
            accounts: [
                .init(address: source.base58EncodedString, isSigner: true, isWritable: true),
                .init(address: destination.base58EncodedString, isSigner: false, isWritable: true),
            ],
            data: SolanaComputeBudgetInstruction.littleEndianBytes(Index.systemTransfer)
                + SolanaComputeBudgetInstruction.littleEndianBytes(lamports)
        )
    }

    static func createAssociatedTokenAccount(
        payer: PublicKey,
        associatedAccount: PublicKey,
        owner: PublicKey,
        mint: PublicKey,
        tokenProgramId: PublicKey
    ) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: MetaplexTokenMetadataProgram.associatedTokenProgramId.base58EncodedString,
            accounts: [
                .init(address: payer.base58EncodedString, isSigner: true, isWritable: true),
                .init(address: associatedAccount.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: owner.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: mint.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: PublicKey.programId.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: tokenProgramId.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: PublicKey.sysvarRent.base58EncodedString, isSigner: false, isWritable: false),
            ],
            data: Data()
        )
    }

    static func transferChecked(
        source: PublicKey,
        mint: PublicKey,
        destination: PublicKey,
        owner: PublicKey,
        amount: UInt64,
        decimals: UInt8,
        tokenProgramId: PublicKey
    ) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: tokenProgramId.base58EncodedString,
            accounts: [
                .init(address: source.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: mint.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: destination.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: owner.base58EncodedString, isSigner: true, isWritable: false),
            ],
            data: Data([Index.transferChecked]) + SolanaComputeBudgetInstruction.littleEndianBytes(amount) + Data([decimals])
        )
    }
}

private extension SolanaTransferInstruction {
    enum Index {
        static let systemTransfer: UInt32 = 2
        static let transferChecked: UInt8 = 12
    }
}
