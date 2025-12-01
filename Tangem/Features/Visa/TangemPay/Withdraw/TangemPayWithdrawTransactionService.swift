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
import TangemFoundation

protocol TangemPayWithdrawTransactionServiceOutput: AnyObject {
    func withdrawTransactionDidSent()
}

protocol TangemPayWithdrawTransactionService {
    func sendWithdrawTransaction(amount: Decimal, destination: String) async throws -> TangemPayWithdrawTransactionResult
    func set(output: TangemPayWithdrawTransactionServiceOutput)

    func hasActiveWithdrawOrder() async throws -> Bool
}

class CommonTangemPayWithdrawTransactionService {
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let fiatItem: FiatItem
    private let signer: any TangemSigner
    private let walletPublicKey: Wallet.PublicKey

    private let activeWithdrawOrderID: ThreadSafeContainer<String?> = .init(nil)
    private weak var output: TangemPayWithdrawTransactionServiceOutput?

    init(
        customerInfoManagementService: any CustomerInfoManagementService,
        fiatItem: FiatItem,
        signer: any TangemSigner,
        walletPublicKey: Wallet.PublicKey
    ) {
        self.customerInfoManagementService = customerInfoManagementService
        self.fiatItem = fiatItem
        self.signer = signer
        self.walletPublicKey = walletPublicKey
    }

    func set(output: TangemPayWithdrawTransactionServiceOutput) {
        self.output = output
    }
}

// MARK: - TangemPayWithdrawTransactionService

extension CommonTangemPayWithdrawTransactionService: TangemPayWithdrawTransactionService {
    func sendWithdrawTransaction(amount: Decimal, destination: String) async throws -> TangemPayWithdrawTransactionResult {
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

        activeWithdrawOrderID.mutate { $0 = response.orderID }
        return response
    }

    func hasActiveWithdrawOrder() async throws -> Bool {
        guard let orderId = activeWithdrawOrderID.read() else {
            return false
        }

        let order = try await customerInfoManagementService.getOrder(orderId: orderId)
        try await Task.sleep(seconds: 5)

        switch order.status {
        case .new, .processing:
            return true
        case .completed, .canceled:
            activeWithdrawOrderID.mutate { $0 = nil }
            return false
        }
    }
}
