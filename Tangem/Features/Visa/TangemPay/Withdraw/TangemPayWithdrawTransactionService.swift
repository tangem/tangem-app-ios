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
import TangemFoundation

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

        try verifyPreSignature(preSignature, against: request)

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
    func verifyPreSignature(
        _ preSignature: TangemPayWithdrawPreSignature,
        against request: TangemPayWithdrawRequest
    ) throws {
        let typedData = preSignature.structuredData

        guard let usdcToken = TangemPayUtilities.usdcTokenItem.token,
              let requestAmountInCents = Decimal(string: request.amountInCents)
        else {
            throw Error.contentMismatch
        }

        let requestAmountInFiat = fiatItem.convertFromCents(value: requestAmountInCents)
        let expectedAmount = requestAmountInFiat * usdcToken.decimalValue

        guard let messageRecipient = typedData.message[MessageKey.recipient]?.stringValue,
              let messageAmount = typedData.message[MessageKey.amount]?.intValue.flatMap(Decimal.init),
              messageRecipient == request.destination,
              messageAmount == expectedAmount
        else {
            throw Error.contentMismatch
        }

        guard typedData.signHash == preSignature.hash else {
            throw Error.hashMismatch
        }
    }
}

private extension CommonTangemPayWithdrawTransactionService {
    /// Field names in the EIP-712 `Withdraw` message returned by the BFF.
    /// Defined by the on-chain `Collateral` v2 contract; must match byte-for-byte.
    enum MessageKey {
        static let recipient = "recipient"
        static let amount = "amount"
    }

    enum Error: LocalizedError {
        case withdrawInProgress
        case contentMismatch
        case hashMismatch
    }
}
