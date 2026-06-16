//
//  HederaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hiero
import CryptoSwift
import TangemSdk
import TangemFoundation

final class HederaTransactionBuilder {
    private let publicKey: Data
    private let curve: EllipticCurve
    private let isTestnet: Bool
    private let timeout: TimeInterval

    private lazy var client: Client = isTestnet
        ? Client.forTestnetWithImmediateUpdate(plaintextOnly: true)
        : Client.forMainnetWithImmediateUpdate(plaintextOnly: true)

    init(publicKey: Data, curve: EllipticCurve, isTestnet: Bool, timeout: TimeInterval = 60) {
        self.publicKey = publicKey
        self.curve = curve
        self.isTestnet = isTestnet
        self.timeout = timeout
    }

    func buildTokenAssociationForSign(
        tokenAssociation: TokenAssociation,
        validStartDate: UnixTimestamp,
        nodeAccountIds: [Int]?
    ) throws -> CompiledTransaction {
        let accountId = try AccountId.fromSolidityAddressOrString(tokenAssociation.accountId)
        let tokenId = try TokenId.fromSolidityAddressOrString(tokenAssociation.contractAddress)
        let transactionId = try makeTransactionId(accountId: accountId, validStartDate: validStartDate)

        let nodeAccountIds = nodeAccountIds?
            .map(UInt64.init)
            .map(AccountId.init(num:))

        // Fees for token association transactions are constant, therefore we don't adjust `maxTransactionFee` for the transaction
        let tokenAssociateTransaction = try TokenAssociateTransaction(accountId: accountId, tokenIds: [tokenId])
            .transactionId(transactionId)
            .nodeAccountIdsIfNotEmpty(nodeAccountIds)
            .freezeWith(client)

        return CompiledTransaction(curve: curve, timeout: timeout, client: client, innerTransaction: tokenAssociateTransaction)
    }

    /// Build transaction for signing.
    /// - parameter nodeAccountIds: A list of consensus network nodes for sending this transaction;
    /// Pass `nil` to let the Hedera SDK network layer select valid and alive consensus network nodes on its own.
    func buildTransferTransactionForSign(
        transaction: Transaction,
        validStartDate: UnixTimestamp,
        nodeAccountIds: [Int]?
    ) throws -> CompiledTransaction {
        guard let feeParams = transaction.fee.parameters as? HederaFeeParams else {
            throw BlockchainSdkError.failedToBuildTx
        }

        // deduct additionalHBARFee, since it's for UI only
        let fee = transaction.fee.amount.value - feeParams.additionalHBARFee

        let feeValue = fee * pow(Decimal(10), transaction.fee.amount.decimals)
        // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
        // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
        let feeRoundedValue = feeValue.rounded(roundingMode: .up)
        let feeAmount = try Hbar(feeRoundedValue, .tinybar)

        let sourceAccountId = try AccountId.fromSolidityAddressOrString(transaction.sourceAddress)
        let transactionId = try makeTransactionId(accountId: sourceAccountId, validStartDate: validStartDate)
        let transactionParams = transaction.params as? HederaTransactionParams

        let nodeAccountIds = nodeAccountIds?
            .map(UInt64.init)
            .map(AccountId.init(num:))

        let transferTransaction = try makeTransferTransaction(
            amount: transaction.amount,
            destinationAddress: transaction.destinationAddress,
            sourceAccountId: sourceAccountId,
            feeParams: feeParams
        )
        .transactionId(transactionId)
        .maxTransactionFee(feeAmount)
        .transactionMemo(transactionParams?.memo ?? "")
        .nodeAccountIdsIfNotEmpty(nodeAccountIds)
        .freezeWith(client)

        logTransaction(transferTransaction)

        // Capturing an existing `Hiero.Client` instance here is not required but may come in handy
        // because the client may already have some useful internal state at this point
        // (like the list of ready-to-use GRCP nodes with health checks already performed)
        return CompiledTransaction(curve: curve, timeout: timeout, client: client, innerTransaction: transferTransaction)
    }

    func buildForSend(transaction: CompiledTransaction, signatures: [Data]) throws -> CompiledTransaction {
        let publicKey = try getPublicKey()
        transaction.addSignatures(publicKey, signatures)

        return transaction
    }

    private func getPublicKey() throws -> Hiero.PublicKey {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return try .fromBytesEd25519(publicKey)
        case .secp256k1:
            let ecdsaKey = try Secp256k1Key(with: publicKey).compress()
            return try .fromBytesEcdsa(ecdsaKey)
        default:
            throw HederaError.unsupportedCurve(curveName: curve.rawValue)
        }
    }

    private func makeTransactionId(accountId: Hiero.AccountId, validStartDate: UnixTimestamp) throws -> Hiero.TransactionId {
        let (validStartDateNSec, multiplicationOverflow) = UInt64(validStartDate.seconds).multipliedReportingOverflow(by: NSEC_PER_SEC)
        if multiplicationOverflow {
            BSDKLogger.error(error: "Unable to create tx id due to multiplication overflow of '\(validStartDate)'")
            throw BlockchainSdkError.failedToBuildTx
        }

        let (unixTimestampNSec, addingOverflow) = validStartDateNSec.addingReportingOverflow(UInt64(validStartDate.nanoseconds))
        if addingOverflow {
            BSDKLogger.error(error: "Unable to create tx id due to adding overflow of '\(validStartDate)'")
            throw BlockchainSdkError.failedToBuildTx
        }

        let validStart = Timestamp(fromUnixTimestampNanos: unixTimestampNSec)

        return TransactionId.withValidStart(accountId, validStart)
    }

    private func makeTransferTransaction(
        amount: Amount,
        destinationAddress: String,
        sourceAccountId: AccountId,
        feeParams: HederaFeeParams
    ) throws -> Hiero.Transaction {
        let transactionValue = amount.value * pow(Decimal(10), amount.decimals)
        let transactionRoundedValue = transactionValue.rounded(roundingMode: .down)

        switch amount.type {
        case .coin:
            let destinationAccountId = try AccountId.fromSolidityAddressOrString(destinationAddress)
            let transactionAmount = try Hbar(transactionRoundedValue, .tinybar)
            return TransferTransaction()
                .hbarTransfer(sourceAccountId, transactionAmount.negated())
                .hbarTransfer(destinationAccountId, transactionAmount)
        case .token(let token) where HederaTokenContractAddressConverter.isERC20TokenAddress(token.contractAddress):
            guard let erc20TransferConfiguration = feeParams.erc20TransferConfiguration else {
                throw BlockchainSdkError.failedToBuildTx
            }

            guard let amountValue = amount.bigUIntValue else {
                throw BlockchainSdkError.failedToBuildTx
            }

            let contractId = try ContractId.fromSolidityAddressOrString(token.contractAddress)
            let transferMethod = TransferERC20TokenMethod(
                destination: erc20TransferConfiguration.recipientEVMAddress.removeHexPrefix(),
                amount: amountValue
            )

            return ContractExecuteTransaction()
                .contractId(contractId)
                .gas(erc20TransferConfiguration.gasLimit)
                .functionParameters(transferMethod.data)
        case .token(let token):
            let destinationAccountId = try AccountId.fromSolidityAddressOrString(destinationAddress)
            let tokenId = try TokenId.fromSolidityAddressOrString(token.contractAddress)
            let transactionAmount = transactionRoundedValue.int64Value
            return TransferTransaction()
                .tokenTransfer(tokenId, sourceAccountId, -transactionAmount)
                .tokenTransfer(tokenId, destinationAccountId, transactionAmount)
        case .reserve, .feeResource:
            throw BlockchainSdkError.failedToBuildTx
        }
    }

    private func logTransaction(_ transaction: Hiero.Transaction) {
        let nodeAccountIds = transaction.nodeAccountIds?.toSet() ?? []
        let transactionId = transaction.transactionId?.toString() ?? "unknown"
        let networkNodes = client.network.filter { nodeAccountIds.contains($0.value) }
        BSDKLogger.info("Constructed tx '\(transactionId)' with the following network nodes: \(networkNodes)")
    }
}

// MARK: - Auxiliary types

extension HederaTransactionBuilder {
    struct TokenAssociation {
        let accountId: String
        let contractAddress: String
    }

    /// Auxiliary type that hides all implementation details (including dependency on `Hedera iOS SDK`).
    struct CompiledTransaction {
        private let curve: EllipticCurve
        private let timeout: TimeInterval
        private let client: Hiero.Client
        private let innerTransaction: Hiero.Transaction

        fileprivate init(
            curve: EllipticCurve,
            timeout: TimeInterval,
            client: Hiero.Client,
            innerTransaction: Hiero.Transaction
        ) {
            self.curve = curve
            self.timeout = timeout
            self.client = client
            self.innerTransaction = innerTransaction
        }

        func hashesToSign() throws -> [Data] {
            let dataToSign = try innerTransaction.signedTransactionsData()
            switch curve {
            case .ed25519, .ed25519_slip0010:
                // When using EdDSA, the original transaction is signed, not its hashes or something else
                return dataToSign
            case .secp256k1:
                return dataToSign.map { $0.sha3(.keccak256) }
            default:
                throw HederaError.unsupportedCurve(curveName: curve.rawValue)
            }
        }

        func addSignatures(_ publicKey: PublicKey, _ signatures: [Data]) {
            innerTransaction.addSignatures(publicKey, signatures)
        }

        func sendAndGetHash() async throws -> String {
            return try await innerTransaction
                .execute(client, timeout)
                .transactionId
                .toString()
        }
    }
}

// MARK: - Convenience extensions

private extension Hiero.Transaction {
    /// Same as `Hiero.Transaction.nodeAccountIds(_:)`, but with empty list checking.
    @discardableResult
    func nodeAccountIdsIfNotEmpty(_ nodeAccountIds: [AccountId]?) -> Self {
        if let nodeAccountIds = nodeAccountIds?.nilIfEmpty {
            return self.nodeAccountIds(nodeAccountIds)
        }

        return self
    }
}

extension Hiero.EntityId {
    /// A dumb convenience factory method for parsing entity IDs in both `<shard>.<realm>.<last>` (Hedera native)
    /// and `[0x]40*HEXDIG` (Solidity/EVM) forms.
    static func fromSolidityAddressOrString<S: StringProtocol>(_ input: S) throws -> Self {
        // Solidity/EVM address parsing rules are stricter, so we're trying to parse Solidity/EVM addresses first
        return try (try? fromSolidityAddress(input)) ?? fromString(input)
    }
}

// MARK: - Unit tests support

extension HederaTransactionBuilder.CompiledTransaction {
    /// - Note: For use in unit tests only or set send transaction error.
    func toBytes() throws -> Data {
        return try innerTransaction.toBytes()
    }
}
