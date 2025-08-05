//
//  Stellart=TransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

@available(iOS 13.0, *)
class StellarTransactionBuilder {
    var sequence: Int64?
    var useTimebounds = true
    /// for tests
    var specificTxTime: TimeInterval?

    private let walletPublicKey: Data
    private let isTestnet: Bool

    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }

    /// Builds and serializes a `ChangeTrustOperation` for a given token, amount, and limit.
    /// This operation can be used to create, update, or remove a trustline to a specific asset.
    /// - Parameters:
    ///   - sourceAddress: The address initiating the operation (usually the user's wallet address).
    ///   - transactionAmount: The amount representing the asset for which the trustline is being set.
    ///   - fee: The network fee to include in the transaction.
    ///   - limit: The trustline limit — use `.max` to create, `.custom` for a specific value, or `.remove` to revoke trust.
    /// - Returns: Transaction hash and serialized XDR, or throws an error.
    func buildChangeTrustOperationForSign(
        transaction: Transaction,
        limit: ChangeTrustOperation.ChangeTrustLimit
    ) throws -> (hash: Data, transaction: stellarsdk.TransactionXDR) {
        guard let assetId = transaction.contractAddress else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let (code, issuer) = try StellarAssetIdParser().getAssetCodeAndIssuer(from: assetId)

        guard let contractKeyPair = try? KeyPair(accountId: issuer),
              let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress),
              let asset = createNonNativeAsset(code: code, issuer: contractKeyPair),
              let changeTrustAsset = asset.toChangeTrustAsset(),
              let limit = limit.value
        else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let operation = ChangeTrustOperation(sourceAccountId: transaction.sourceAddress, asset: changeTrustAsset, limit: limit)
        return try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: .none)
    }

    func buildForSign(
        targetAccountResponse: StellarTargetAccountResponse,
        transaction: Transaction,
    ) throws -> (hash: Data, transaction: stellarsdk.TransactionXDR) {
        guard let destinationKeyPair = try? KeyPair(accountId: transaction.destinationAddress),
              let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress)
        else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let memo = (transaction.params as? StellarTransactionParams)?.memo ?? Memo.text("")
        let isAccountCreated = targetAccountResponse.accountCreated
        let amountToCreateAccount: Decimal = StellarWalletManager.Constants.minAmountToCreateCoinAccount

        switch transaction.amount.type {
        case .coin:
            if !isAccountCreated, transaction.amount.value < amountToCreateAccount {
                throw BlockchainSdkError.noAccount(
                    message: StellarError.xlmCreateAccount.localizedDescription,
                    amountToCreate: amountToCreateAccount
                )
            }

            let operation = isAccountCreated ? try PaymentOperation(
                sourceAccountId: transaction.sourceAddress,
                destinationAccountId: transaction.destinationAddress,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: transaction.amount.value
            ) :
                CreateAccountOperation(sourceAccountId: nil, destination: destinationKeyPair, startBalance: transaction.amount.value)

            let serializedOperation = try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
            return serializedOperation

        case .token:
            guard let assetId = transaction.contractAddress else {
                throw BlockchainSdkError.failedToBuildTx
            }

            let (code, issuer) = try StellarAssetIdParser().getAssetCodeAndIssuer(from: assetId)

            guard let keyPair = try? KeyPair(accountId: issuer),
                  let asset = createNonNativeAsset(code: code, issuer: keyPair)
            else {
                throw BlockchainSdkError.failedToBuildTx
            }

            guard isAccountCreated else {
                throw StellarError.assetNoAccountOnDestination
            }

            guard targetAccountResponse.trustlineCreated else {
                throw StellarError.assetNoTrustline
            }

            guard transaction.amount.value > 0 else {
                throw BlockchainSdkError.failedToBuildTx
            }

            let operation = try PaymentOperation(
                sourceAccountId: transaction.sourceAddress,
                destinationAccountId: transaction.destinationAddress,
                asset: asset,
                amount: transaction.amount.value
            )

            let serializedOperation = try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
            return serializedOperation

        case .reserve, .feeResource:
            throw BlockchainSdkError.failedToBuildTx
        }
    }

    func buildForSend(signature: Data, transaction: TransactionXDR) -> String? {
        var transaction = transaction
        let hint = walletPublicKey.suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
        transaction.addSignature(signature: decoratedSignature)
        let envelope = try? transaction.encodedEnvelope()
        return envelope
    }

    private func createNonNativeAsset(code: String, issuer: KeyPair) -> Asset? {
        if code.count >= 1, code.count <= 4 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: code, issuer: issuer)
        } else if code.count >= 5, code.count <= 12 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: code, issuer: issuer)
        } else {
            return nil
        }
    }

    private func serializeOperation(_ operation: stellarsdk.Operation, sourceKeyPair: KeyPair, memo: Memo) throws -> (hash: Data, transaction: stellarsdk.TransactionXDR) {
        guard let xdrOperation = try? operation.toXDR(),
              let seqNumber = sequence else {
            throw BlockchainSdkError.failedToBuildTx
        }

        // Extended the interval from 2 minutes to 5 to make sure the transaction lives longer
        // and has more chance of getting through when the network is under heavy load
        let currentTime = specificTxTime ?? Date().timeIntervalSince1970
        let minTime = currentTime - 2.5 * 60.0
        let maxTime = currentTime + 2.5 * 60.0

        let cond: PreconditionsXDR = useTimebounds ? .time(TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime))) : .none
        let tx = TransactionXDR(
            sourceAccount: sourceKeyPair.publicKey,
            seqNum: seqNumber + 1,
            cond: cond,
            memo: memo.toXDR(),
            operations: [xdrOperation]
        )

        let network = isTestnet ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return (hash, tx)
    }
}

extension Asset {
    func toChangeTrustAsset() -> ChangeTrustAsset? {
        ChangeTrustAsset(type: type, code: code, issuer: issuer)
    }
}
