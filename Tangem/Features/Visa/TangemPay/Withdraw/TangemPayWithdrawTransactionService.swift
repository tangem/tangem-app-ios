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
import TangemPay

protocol TangemPayWithdrawTransactionService {
    func sendWithdrawTransaction(amount: Decimal, destination: String, walletPublicKey: Wallet.PublicKey) async throws -> TangemPayWithdrawTransactionResult

    func hasActiveWithdrawOrder() async throws -> Bool
}

class CommonTangemPayWithdrawTransactionService {
    private let customerService: any TangemPayCustomerService
    private let fiatItem: FiatItem
    private let signer: any TangemSigner

    private let activeWithdrawOrderID: ThreadSafeContainer<String?> = .init(nil)

    init(
        customerService: any TangemPayCustomerService,
        fiatItem: FiatItem,
        signer: any TangemSigner,
    ) {
        self.customerService = customerService
        self.fiatItem = fiatItem
        self.signer = signer
    }
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

        let preSignature = try await customerService
            .getWithdrawPreSignatureInfo(request: request)

        let signatureInfo = try await signer
            .sign(hash: preSignature.hash, walletPublicKey: walletPublicKey)
            .async()

        let unmarshalledSignature = try signatureInfo.unmarshal()

        let signature = TangemPayWithdrawSignature(
            sender: preSignature.sender,
            signature: unmarshalledSignature,
            salt: preSignature.salt
        )

        let response = try await customerService
            .sendWithdrawTransaction(request: request, signature: signature)

        activeWithdrawOrderID.mutate { $0 = response.orderID }
        return response
    }

    func hasActiveWithdrawOrder() async throws -> Bool {
        guard let orderId = activeWithdrawOrderID.read() else {
            return false
        }

        let order = try await customerService.getOrder(orderId: orderId)
        switch order.status {
        case .new, .processing:
            return true
        case .completed, .canceled:
            activeWithdrawOrderID.mutate { $0 = nil }
            return false
        }
    }
}
