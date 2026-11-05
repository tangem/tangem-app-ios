//
//  JointAccountPendingOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemMacro

/// An unfinished operation of the account, with the wallet it is made through: what a screen shows of it, and what
/// this member can do about it.
struct JointAccountPendingOperation: Equatable {
    var tokenItem: TokenItem { wallet.tokenItem }
    var amount: Amount? { operationAmount() }
    var fee: Amount? { operationFee() }
    var destination: String { innerCallType.destination }
    var id: String { operation.id }
    var status: JointAccountOperationStatus { operation.status }
    var finishedAt: Date? { operation.finishedAt }
    var initiatorAddress: String { operation.initiator }
    var signatures: [JointAccountOperation.Signature] { operation.signatures }
    /// Includes the initiator's signature, so it is never zero for an operation that exists.
    var collectedSignaturesCount: Int { operation.signatures.filter { $0.state == .signed }.count }
    var standing: Standing { memberStanding() }
    var canSign: Bool { isSignable() }
    var canReject: Bool { isRejectable() }
    var didChangePublisher: AnyPublisher<JointAccountPendingOperation, Never> { makeDidChangePublisher() }

    let wallet: JointAccountWallet
    let initiator: Initiator
    let innerCallType: SafeInnerCallType
    let feeTokenItem: TokenItem?

    private let operation: JointAccountOperation
    @IgnoredEquatable
    private var operationPublisher: AnyPublisher<JointAccountOperation, Never>

    init(
        wallet: JointAccountWallet,
        initiator: Initiator,
        operation: JointAccountOperation,
        operationPublisher: AnyPublisher<JointAccountOperation, Never>,
        innerCallType: SafeInnerCallType,
        feeTokenItem: TokenItem?
    ) {
        self.wallet = wallet
        self.initiator = initiator
        self.operation = operation
        self.operationPublisher = operationPublisher
        self.innerCallType = innerCallType
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - Actions

extension JointAccountPendingOperation {
    /// Counts this member's signature towards the threshold.
    func sign() async throws {
        try await wallet.sign(operation)
    }

    /// Declines the operation, which the initiator's own answer ends outright.
    func reject() async throws {
        try await wallet.reject(operation)
    }
}

// MARK: - Auxiliary types

extension JointAccountPendingOperation {
    @CaseFlagable
    enum Initiator: Equatable {
        case me
        case member(name: String)
        case unlisted(address: String)
    }

    enum Standing {
        case noDecisionYet
        case signed
        case declined
        /// Own key of the account not derived yet
        case unavailable
        /// Own answer in a state this version cannot read
        case unreadable
    }
}

// MARK: - JointAccountPendingOperationPoller protocol conformance

extension JointAccountPendingOperation: JointAccountPendingOperationPoller {
    func requestFrequentUpdates() -> AnyCancellable? {
        wallet.account?.jointAccountPendingOperationsProvider.requestFrequentUpdates(operationId: operation.id)
    }
}

// MARK: - Private

private extension JointAccountPendingOperation {
    func makeDidChangePublisher() -> AnyPublisher<JointAccountPendingOperation, Never> {
        operationPublisher
            .map { [self] operation in updating(operation: operation) }
            .eraseToAnyPublisher()
    }

    func updating(operation: JointAccountOperation) -> JointAccountPendingOperation {
        JointAccountPendingOperation(
            wallet: wallet,
            initiator: initiator,
            operation: operation,
            operationPublisher: operationPublisher,
            innerCallType: innerCallType,
            feeTokenItem: feeTokenItem
        )
    }

    func memberStanding() -> Standing {
        guard let ownAddress = try? wallet.ownAddress() else {
            return .unavailable
        }

        guard !initiator.isMe else {
            return .signed
        }

        let signature = operation.signatures.first { $0.address.caseInsensitiveEquals(to: ownAddress) }

        return switch signature?.state {
        case .none: .noDecisionYet
        case .signed: .signed
        case .declined: .declined
        case .unknown: .unreadable
        }
    }

    func isSignable() -> Bool {
        operation.status == .awaitingSignatures && standing == .noDecisionYet
    }

    func isRejectable() -> Bool {
        guard operation.status == .awaitingSignatures else {
            return false
        }

        return switch standing {
        case .noDecisionYet, .signed, .unreadable: true
        case .declined, .unavailable: false
        }
    }

    /// - Returns: `nil` for an amount too large to state as a `Decimal`, which is better shown as unknown than
    /// understated.
    func operationAmount() -> Amount? {
        guard let value = innerCallType.value.decimal else {
            return nil
        }

        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value / tokenItem.decimalValue)
    }

    /// - Returns: `nil` for a fee in a token this wallet has not added, which it cannot word.
    func operationFee() -> Amount? {
        guard let feeTokenItem, let value = operation.safeTransaction.fee.decimal else {
            return nil
        }

        return Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value / feeTokenItem.decimalValue)
    }
}
