//
//  TezosWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import stellarsdk
import TangemLocalization

class TezosWalletManager: BaseManager, WalletManager {
    var txBuilder: TezosTransactionBuilder!
    var networkService: TezosNetworkService!

    var currentHost: String { networkService.host }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case .failure(let error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    private func updateWallet(with response: TezosAddress) {
        txBuilder.counter = response.counter
        txBuilder.isPublicKeyRevealed = response.isPublicKeyRevealed

        if response.balance != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: response.balance)
    }
}

extension TezosWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        guard let contents = txBuilder.buildContents(transaction: transaction) else {
            return .sendTxFail(error: BlockchainSdkError.failedToBuildTx)
        }

        return networkService
            .getHeader()
            .tryMap { [weak self] header -> (TezosHeader, String) in
                guard let self = self else { throw BlockchainSdkError.empty }

                let forged = try txBuilder
                    .forgeContents(headerHash: header.hash, contents: contents)

                return (header, forged)
            }
            .flatMap { [weak self] header, forgedContents -> AnyPublisher<(header: TezosHeader, forgedContents: String, signature: Data), Error> in
                guard let self = self else { return .emptyFail }

                guard let txToSign: Data = txBuilder.buildToSign(forgedContents: forgedContents) else {
                    return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
                }

                return signer.sign(
                    hash: txToSign,
                    walletPublicKey: wallet.publicKey
                )
                .map { signature -> (TezosHeader, String, Data) in
                    return (header, forgedContents, signature)
                }
                .eraseToAnyPublisher()
            }
            .flatMap { [weak self] header, forgedContents, signature -> AnyPublisher<(String, Data), Error> in
                guard let self = self else { return .emptyFail }

                return networkService
                    .checkTransaction(protocol: header.protocol, hash: header.hash, contents: contents, signature: encodeSignature(signature))
                    .map { _ in (forgedContents, signature) }
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] forgedContents, signature -> AnyPublisher<TransactionSendResult, Error> in
                guard let self else { return .emptyFail }

                let rawTransaction = txBuilder.buildToSend(signature: signature, forgedContents: forgedContents)

                return networkService
                    .sendTransaction(rawTransaction)
                    .tryMap { [weak self] response in
                        guard let self = self else { throw BlockchainSdkError.empty }

                        let mapper = PendingTransactionRecordMapper()
                        let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: rawTransaction)
                        wallet.addPendingTransaction(record)
                        return TransactionSendResult(hash: rawTransaction, currentProviderHost: currentHost)
                    }
                    .mapAndEraseSendTxError(tx: rawTransaction)
                    .eraseToAnyPublisher()
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }

    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        // We assume that account is not created therefore we're adding allocation fee
        var fee = TezosFee.transaction.rawValue + TezosFee.allocation.rawValue

        if txBuilder.isPublicKeyRevealed == false {
            fee += TezosFee.reveal.rawValue
        }

        let amountFee = Amount(with: wallet.blockchain, value: fee)

        return .justWithError(output: [Fee(amountFee)])
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService.getInfo(address: destination)
            .tryMap { [weak self] destinationInfo -> [Fee] in
                guard let self = self else { throw BlockchainSdkError.empty }

                var fee = TezosFee.transaction.rawValue
                if txBuilder.isPublicKeyRevealed == false {
                    fee += TezosFee.reveal.rawValue
                }

                if destinationInfo.balance == 0 {
                    fee += TezosFee.allocation.rawValue
                }

                let amountFee = Amount(with: wallet.blockchain, value: fee)
                return [Fee(amountFee)]
            }
            .eraseToAnyPublisher()
    }

    private func encodeSignature(_ signature: Data) -> String {
        let edsigPrefix = TezosPrefix.signaturePrefix(for: wallet.blockchain.curve)
        let prefixedSignature = edsigPrefix + signature
        let checksum = prefixedSignature.getDoubleSha256().prefix(4)
        let prefixedSignatureWithChecksum = prefixedSignature + checksum
        return Base58.encode(prefixedSignatureWithChecksum)
    }
}

extension TezosWalletManager: ThenProcessable {}

// MARK: - WithdrawalNotificationProvider

extension TezosWalletManager: WithdrawalNotificationProvider {
    private var withdrawalMinimumAmount: Decimal {
        Decimal(string: "0.000001")!
    }

    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        guard
            let walletAmount = wallet.amounts[.coin],
            amount + fee.amount == walletAmount
        else {
            return nil
        }

        return .feeIsTooHigh(reduceAmountBy: Amount(with: walletAmount, value: withdrawalMinimumAmount))
    }
}
