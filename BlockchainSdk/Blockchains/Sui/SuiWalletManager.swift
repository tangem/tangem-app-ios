//
// SuiWalletManager.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class SuiWalletManager: BaseManager, WalletManager {
    let networkService: SuiNetworkService
    let transactionBuilder: SuiTransactionBuilder

    init(wallet: Wallet, networkService: SuiNetworkService, transactionBuilder: SuiTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let tokens = cardTokens
        cancellable = networkService.getBalance(address: wallet.address, coinType: .sui, cursor: nil)
            .sink(receiveCompletion: { [weak self] completionSubscriptions in
                if case .failure(let error) = completionSubscriptions {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] result in
                switch result {
                case .success(let coins):
                    self?.updateWallet(coins: coins, tokens: tokens)
                    completion(.success(()))
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            })
    }

    func updateWallet(coins: [SuiGetCoins.Coin], tokens: [Token]) {
        let objects = coins.compactMap {
            try? SuiCoinObject.from($0)
        }

        let totalBalance = objects
            .filter { $0.coinType == SuiCoinObject.CoinType.sui }
            .reduce(into: Decimal.zero) { partialResult, coin in
                partialResult += coin.balance
            }

        let coinValue = totalBalance / wallet.blockchain.decimalValue

        if coinValue != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        for token in tokens {
            let tokenBalance = objects
                .filter {
                    do {
                        let normalizeContractType = try SuiCoinObject.CoinType(string: token.contractAddress)
                        return $0.coinType.string == normalizeContractType.string
                    } catch {
                        return false
                    }
                }
                .reduce(into: Decimal.zero) { partialResult, coin in
                    partialResult += coin.balance
                }

            let decimalTokenBalance = tokenBalance / token.decimalValue
            wallet.add(tokenValue: decimalTokenBalance, for: token)
        }

        wallet.add(coinValue: coinValue)
        transactionBuilder.update(coins: objects)
    }
}

extension SuiWalletManager: BlockchainDataProvider {
    var currentHost: String {
        networkService.host
    }
}

extension SuiWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        return networkService.getReferenceGasPrice()
            .withWeakCaptureOf(self)
            .flatMap { manager, referencedGasPrice -> AnyPublisher<SuiInspectTransaction, any Error> in
                guard let decimalGasPrice = Decimal(stringValue: referencedGasPrice) else {
                    return .anyFail(error: BlockchainSdkError.failedToParseNetworkResponse())
                }

                return manager.estimateFee(amount: amount, destination: destination, referenceGasPrice: decimalGasPrice)
            }
            .withWeakCaptureOf(self)
            .tryMap { manager, inspectTransaction in
                guard inspectTransaction.effects.isSuccess() else {
                    throw BlockchainSdkError.failedToGetFee
                }

                guard
                    let usedGasPrice = Decimal(stringValue: inspectTransaction.input.gasData.price),
                    let computationCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.computationCost),
                    let storageCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.storageCost)
                else {
                    throw BlockchainSdkError.failedToParseNetworkResponse()
                }

                let budget = computationCost + storageCost
                let feeAmount = Amount(with: manager.wallet.blockchain, value: budget / manager.wallet.blockchain.decimalValue)

                let params = SuiFeeParameters(gasPrice: usedGasPrice, gasBudget: budget)
                return [Fee(feeAmount, parameters: params)]
            }
            .eraseToAnyPublisher()
    }

    private func estimateFee(amount: Amount, destination: String, referenceGasPrice: Decimal) -> AnyPublisher<SuiInspectTransaction, any Error> {
        return Result {
            try transactionBuilder.buildForInspect(amount: amount, destination: destination, referenceGasPrice: referenceGasPrice)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, base64tx: String) -> AnyPublisher<SuiInspectTransaction, Error> in
            manager.networkService.dryTransaction(transaction: base64tx)
        }
        .mapError { [weak self] error in
            guard
                let self,
                transactionBuilder.checkIfCoinGasBalanceIsNotEnoughForTokenTransaction()
            else {
                return error
            }

            return SuiError.oneSuiCoinIsRequiredForTokenTransaction
        }
        .eraseToAnyPublisher()
    }
}

extension SuiWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Result {
            try transactionBuilder.buildForSign(transaction: transaction)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, dataHash: Data) -> AnyPublisher<SignatureInfo, Error> in
            signer.sign(hash: dataHash, walletPublicKey: manager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, signatureInfo -> (txBytes: String, signature: String) in
            let output = try manager.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo.signature)
            return output
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, builtTransaction -> AnyPublisher<SuiExecuteTransaction, Error> in
            return manager.networkService
                .sendTransaction(transaction: builtTransaction.txBytes, signature: builtTransaction.signature)
                .mapAndEraseSendTxError(tx: builtTransaction.txBytes)
                .eraseToAnyPublisher()
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, tx in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: tx.digest)

            manager.wallet.addPendingTransaction(record)

            return TransactionSendResult(hash: tx.digest, currentProviderHost: manager.currentHost)
        }
        .mapSendTxError()
        .eraseToAnyPublisher()
    }
}
