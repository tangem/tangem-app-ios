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
    func sendWithdrawTransaction(
        amount: Decimal,
        destination: String,
        walletPublicKey: Wallet.PublicKey,
        target: TangemPayWithdrawTarget?
    ) async throws -> TangemPayWithdrawTransactionResult
    func set(output: TangemPayWithdrawTransactionServiceOutput) async

    func hasActiveWithdrawOrder() async throws -> Bool
}

actor CommonTangemPayWithdrawTransactionService {
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let fiatItem: FiatItem
    private let signerFactory: TangemSignerFactory

    private var activeWithdrawOrderID: String?
    private var isWithdrawInProgress: Bool = false

    private weak var output: TangemPayWithdrawTransactionServiceOutput?

    init(
        customerInfoManagementService: any CustomerInfoManagementService,
        fiatItem: FiatItem,
        signerFactory: TangemSignerFactory,
    ) {
        self.customerInfoManagementService = customerInfoManagementService
        self.fiatItem = fiatItem
        self.signerFactory = signerFactory
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
        walletPublicKey: Wallet.PublicKey,
        target: TangemPayWithdrawTarget?
    ) async throws -> TangemPayWithdrawTransactionResult {
        if isWithdrawInProgress {
            throw Error.withdrawInProgress
        }

        isWithdrawInProgress = true
        defer { isWithdrawInProgress = false }

        // amount_in_cents must be a whole number of cents — drop any sub-cent fraction that
        // slips in from amounts entered with 3+ decimal places (e.g. 18.023 -> 1802, not 1802.3).
        let amountInCents = fiatItem.convertToCents(value: amount).rounded(roundingMode: .down).description
        let request = TangemPayWithdrawRequest(
            amountInCents: amountInCents,
            destination: destination,
            target: target
        )

        let preSignature = try await customerInfoManagementService
            .getWithdrawPreSignatureInfo(request: request)

        try Self.verifyPreSignature(preSignature, against: request, fiatItem: fiatItem)

        let signatureInfo = try await signerFactory
            .makeSigner()
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
        case .completed, .canceled, .undefined:
            if activeWithdrawOrderID == orderId {
                activeWithdrawOrderID = nil
            }
            return false
        }
    }
}

extension CommonTangemPayWithdrawTransactionService {
    static func verifyPreSignature(
        _ preSignature: TangemPayWithdrawPreSignature,
        against request: TangemPayWithdrawRequest,
        fiatItem: FiatItem
    ) throws {
        let typedData = preSignature.structuredData

        guard let requestAmountInCents = Decimal(string: request.amountInCents) else {
            throw Error.contentMismatch
        }

        let decimalCount = TangemPayUtilities.tokenDecimalCount(chainId: request.target?.chainId)
        let requestAmountInFiat = fiatItem.convertFromCents(value: requestAmountInCents)
        let expectedAmount = requestAmountInFiat * pow(10, decimalCount)

        // An untargeted request names no network, so there is nothing to hold the answer to.
        if let target = request.target {
            guard let domainChainId = typedData.domain[DomainKey.chainId].flatMap(Self.chainId(from:)),
                  let messageAsset = typedData.message[MessageKey.asset]?.stringValue,
                  domainChainId == target.chainId,
                  messageAsset.caseInsensitiveCompare(target.tokenContractAddress) == .orderedSame
            else {
                throw Error.networkMismatch
            }
        }

        guard let messageRecipient = typedData.message[MessageKey.recipient]?.stringValue,
              let messageAmount = typedData.message[MessageKey.amount].flatMap(Self.amount(from:)),
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
        static let asset = "asset"
        static let recipient = "recipient"
        static let amount = "amount"
    }

    enum DomainKey {
        static let chainId = "chainId"
    }

    /// `uint256` fields reach us as a JSON number or as a quoted string, depending on the environment.
    static func chainId(from json: JSON) -> Int? {
        json.intValue ?? json.stringValue.flatMap { Int($0) }
    }

    static func amount(from json: JSON) -> Decimal? {
        json.intValue.map { Decimal($0) } ?? json.stringValue.flatMap { Decimal(string: $0) }
    }

    enum Error: LocalizedError {
        case withdrawInProgress
        case contentMismatch
        case hashMismatch
        case networkMismatch
    }
}
