//
//  SuiWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class SuiWalletManager: BaseWalletManager, WalletManager {
    let networkService: SuiNetworkService
    let transactionBuilder: SuiTransactionBuilder

    init(wallet: Wallet, networkService: SuiNetworkService, transactionBuilder: SuiTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    func updateWalletManager(address: String) async throws {
        do {
            async let balances = networkService.getBalances(address: address).async()
            async let coins = networkService.getCoins(address: address).async()

            try await updateWallet(balances: balances, coins: coins, tokens: cardTokens)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func updateWallet(balances: [SuiBalance], coins: [SuiGetCoins.Coin], tokens: [Token]) {
        let objects = coins.compactMap {
            try? SuiCoinObject.from($0)
        }

        let totalBalance = balances.first { $0.coinType == .sui }?.balance ?? .zero
        let coinValue = totalBalance / wallet.blockchain.decimalValue

        if coinValue != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        for token in tokens {
            let coinType = try? SuiCoinObject.CoinType(string: token.contractAddress)
            let tokenBalance = balances.first { $0.coinType == coinType }?.balance ?? .zero

            let decimalTokenBalance = tokenBalance / token.decimalValue
            wallet.add(tokenValue: decimalTokenBalance, for: token)
        }

        wallet.add(coinValue: coinValue)
        transactionBuilder.update(coins: objects, balances: balances)
    }
}

extension SuiWalletManager: BlockchainDataProvider {
    var currentHost: String {
        networkService.host
    }
}

extension SuiWalletManager: TransactionFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        return networkService.getReferenceGasPrice()
            .zip(getServiceInfoIfNeeded())
            .withWeakCaptureOf(self)
            .flatMap { manager, output -> AnyPublisher<SuiInspectTransaction, any Error> in
                let (referencedGasPrice, serviceInfo) = output

                guard let decimalGasPrice = Decimal(stringValue: referencedGasPrice) else {
                    return .anyFail(error: BlockchainSdkError.failedToParseNetworkResponse())
                }

                return manager.estimateFee(
                    amount: amount,
                    destination: destination,
                    referenceGasPrice: decimalGasPrice,
                    serviceInfo: serviceInfo
                )
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

    private func estimateFee(
        amount: Amount,
        destination: String,
        referenceGasPrice: Decimal,
        serviceInfo: SuiServiceInfo?
    ) -> AnyPublisher<SuiInspectTransaction, any Error> {
        return Result {
            try transactionBuilder.buildForInspect(
                amount: amount,
                destination: destination,
                referenceGasPrice: referenceGasPrice,
                serviceInfo: serviceInfo
            )
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, base64tx: String) -> AnyPublisher<SuiInspectTransaction, Error> in
            manager.networkService.dryTransaction(transaction: base64tx)
        }
        .mapError { [weak self] error in
            guard
                let self,
                transactionBuilder.checkIfSuiBalanceIsNotEnoughForTokenTransaction()
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
        return getServiceInfoIfNeeded()
            .withWeakCaptureOf(self)
            .tryMap { manager, serviceInfo -> (transactionBytes: String, dataHash: Data) in
                let transactionBytes = try manager.transactionBuilder.buildTransaction(transaction: transaction, serviceInfo: serviceInfo)
                let dataHash = try manager.transactionBuilder.buildForSign(transactionBytes: transactionBytes)
                return (transactionBytes, dataHash)
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, output -> AnyPublisher<(transactionBytes: String, signatureInfo: SignatureInfo), Error> in
                signer.sign(hash: output.dataHash, walletPublicKey: manager.wallet.publicKey)
                    .map { (output.transactionBytes, $0) }
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .tryMap { manager, output -> (txBytes: String, signature: String) in
                try manager.transactionBuilder.buildForSend(
                    transactionBytes: output.transactionBytes,
                    signature: output.signatureInfo.signature
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, builtTransaction -> AnyPublisher<SuiExecuteTransaction, Error> in
                return manager.networkService
                    .sendTransaction(transaction: builtTransaction.txBytes, signature: builtTransaction.signature)
                    .mapAndEraseSendTxError(tx: builtTransaction.txBytes, currentHost: manager.currentHost)
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .tryMap { manager, tx in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: tx.digest)

                manager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: tx.digest, currentProviderHost: manager.currentHost)
            }
            .mapSendTxError(currentHost: currentHost)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension SuiWalletManager {
    func getServiceInfoIfNeeded() -> AnyPublisher<SuiServiceInfo?, Error> {
        guard transactionBuilder.requiresServiceInfo else {
            return .justWithError(output: nil)
        }

        return networkService.getServiceInfo()
            .map { $0 }
            .eraseToAnyPublisher()
    }
}
