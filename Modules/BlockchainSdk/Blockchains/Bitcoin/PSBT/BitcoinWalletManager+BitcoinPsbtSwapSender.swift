//
//  BitcoinWalletManager+BitcoinPsbtSwapSender.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

extension BitcoinWalletManager: BitcoinPsbtSwapSender {
    func send(psbtBase64: String, destination: String, signer: TransactionSigner) async throws -> TransactionSendResult {
        let owners: [Data: DerivationPublicKey] = wallet.addresses.reduce(into: [:]) { result, address in
            guard let lockingScript = (address as? LockingScriptAddress)?.lockingScript,
                  case .publicKey(let key)? = lockingScript.spendable else {
                return
            }

            result[lockingScript.data] = key
        }

        let ownerScriptPubKeys = Set(owners.keys)

        let ownedInputs = try BitcoinPsbtSigningBuilder.ownedInputs(
            psbtBase64: psbtBase64,
            ownerScriptPubKeys: ownerScriptPubKeys
        )

        guard !ownedInputs.isEmpty else {
            throw BitcoinError.noSignableInputs
        }

        let signInputs = ownedInputs.map { BitcoinPsbtSigningBuilder.SignInput(index: $0.index) }
        let hashes = try BitcoinPsbtSigningBuilder.hashesToSign(psbtBase64: psbtBase64, signInputs: signInputs)

        let signData = try zip(ownedInputs, hashes).map { input, hash -> SignData in
            guard let key = owners[input.scriptPubKey] else {
                throw BitcoinError.noSignableInputs
            }

            return SignData(derivationPath: key.derivationPath, hashes: [hash], publicKey: key.publicKey)
        }

        let signatures = try await signer
            .sign(dataToSign: signData, walletPublicKey: wallet.publicKey)
            .async()

        let signedPsbt = try BitcoinPsbtSigningBuilder.applySignaturesAndFinalize(
            psbtBase64: psbtBase64,
            signInputs: signInputs,
            signatures: signatures,
            publicKeys: signData.map(\.publicKey)
        )

        let rawTransactionHex = try BitcoinPsbtSigningBuilder.extractRawTransactionHex(finalizedPsbtBase64: signedPsbt)
        let result = try await networkService.send(transaction: rawTransactionHex).async()

        addPendingTransaction(
            psbtBase64: psbtBase64,
            ownerScriptPubKeys: ownerScriptPubKeys,
            destination: destination,
            hash: result.hash
        )

        return result
    }

    private func addPendingTransaction(psbtBase64: String, ownerScriptPubKeys: Set<Data>, destination: String, hash: String) {
        guard let sentAmount = try? BitcoinPsbtSigningBuilder.sentAmount(psbtBase64: psbtBase64, ownerScriptPubKeys: ownerScriptPubKeys),
              let fee = try? BitcoinPsbtSigningBuilder.fee(psbtBase64: psbtBase64) else {
            return
        }

        let decimalValue = wallet.blockchain.decimalValue
        let record = PendingTransactionRecord(
            hash: hash,
            source: wallet.address,
            destination: destination,
            amount: Amount(with: wallet.blockchain, value: Decimal(sentAmount) / decimalValue),
            fee: Fee(Amount(with: wallet.blockchain, value: Decimal(fee) / decimalValue)),
            date: Date(),
            isIncoming: false,
            transactionType: .transfer
        )

        wallet.addPendingTransaction(record)
    }
}
