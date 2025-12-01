//
//  TangemPayWithdrawTransactionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemVisa
import TangemExpress

protocol TangemPayWithdrawTransactionService {
    func sendWithdrawTransaction(
        amount: Decimal,
        destination: String,
        walletPublicKey: Wallet.PublicKey
    ) async throws -> TangemPayWithdrawTransactionResult
}

struct CommonTangemPayWithdrawTransactionService {
    let customerInfoManagementService: any CustomerInfoManagementService
    let fiatItem: FiatItem
    let signer: any TangemSigner
}

// MARK: - TangemPayWithdrawTransactionService

extension CommonTangemPayWithdrawTransactionService: TangemPayWithdrawTransactionService {
    func sendWithdrawTransaction(
        amount: Decimal,
        destination: String,
        walletPublicKey: Wallet.PublicKey
    ) async throws -> TangemPayWithdrawTransactionResult {
        let amountInCents = fiatItem.convertToCents(value: amount).description
        let request = TangemPayWithdrawRequest(amount: amount, amountInCents: amountInCents, destination: destination)

        let preSignature = try await customerInfoManagementService
            .getWithdrawPreSignatureInfo(request: request)

        let signatureInfo = try await signer
            .sign(hash: preSignature.hash, walletPublicKey: walletPublicKey)
            .async()

        let signature = TangemPayWithdrawSignature(
            sender: preSignature.sender,
            signature: signatureInfo.signature,
            salt: preSignature.salt
        )

        let response = try await customerInfoManagementService
            .sendWithdrawTransaction(request: request, signature: signature)

        return response
    }
}
