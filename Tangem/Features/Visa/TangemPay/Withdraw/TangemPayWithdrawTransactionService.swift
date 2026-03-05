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
import TangemPay

protocol TangemPayWithdrawTransactionServiceOutput: AnyObject {
    func withdrawTransactionDidSent()
}

protocol TangemPayWithdrawTransactionService {
    func getOrder(id: String) async throws -> TangemPayOrderResponse
    func sendWithdrawTransaction(amount: Decimal, destination: String, walletPublicKey: Wallet.PublicKey) async throws -> TangemPayWithdrawTransactionResult
    func set(output: TangemPayWithdrawTransactionServiceOutput) async

    func hasActiveWithdrawOrder() async throws -> Bool
}

actor CommonTangemPayWithdrawTransactionService {
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let fiatItem: FiatItem
    private let signer: any TangemSigner

    private var activeWithdrawOrderID: String?
    private var isWithdrawInProgress: Bool = false

    private weak var output: TangemPayWithdrawTransactionServiceOutput?

    init(
        customerInfoManagementService: any CustomerInfoManagementService,
        fiatItem: FiatItem,
        signer: any TangemSigner,
    ) {
        self.customerInfoManagementService = customerInfoManagementService
        self.fiatItem = fiatItem
        self.signer = signer
    }
}

// MARK: - TangemPayWithdrawTransactionService

extension CommonTangemPayWithdrawTransactionService: TangemPayWithdrawTransactionService {
    func getOrder(id: String) async throws -> TangemPayOrderResponse {
        try await customerInfoManagementService.getOrder(orderId: id)
    }

    func sendWithdrawTransaction(
        amount: Decimal,
        destination: String,
        walletPublicKey: Wallet.PublicKey
    ) async throws -> TangemPayWithdrawTransactionResult {
        if isWithdrawInProgress {
            throw Error.withdrawInProgress
        }

        isWithdrawInProgress = true
        defer { isWithdrawInProgress = false }

        let amountInCents = fiatItem.convertToCents(value: amount).description
        let request = TangemPayWithdrawRequest(amount: amount, amountInCents: amountInCents, destination: destination)

        let preSignature = try await customerInfoManagementService
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

        let response = try await customerInfoManagementService
            .sendWithdrawTransaction(request: request, signature: signature)

        activeWithdrawOrderID = response.orderID
        return response
    }

    func set(output: TangemPayWithdrawTransactionServiceOutput) {
        self.output = output
    }

    func hasActiveWithdrawOrder() async throws -> Bool {
        if isWithdrawInProgress {
            return true
        }

        guard let orderId = activeWithdrawOrderID else {
            return false
        }

        let order = try await customerInfoManagementService.getOrder(orderId: orderId)
        switch order.status {
        case .new, .processing:
            return true
        case .completed, .canceled:
            if activeWithdrawOrderID == orderId {
                activeWithdrawOrderID = nil
            }
            return false
        }
    }
}

private extension CommonTangemPayWithdrawTransactionService {
    enum Error: LocalizedError {
        case withdrawInProgress
    }
}
