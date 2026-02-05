//
//  AptosWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AptosWalletManager: BaseManager {
    // MARK: - Private Properties

    private let transactionBuilder: AptosTransactionBuilder
    private let networkService: AptosNetworkService

    // MARK: - Init

    init(wallet: Wallet, transactionBuilder: AptosTransactionBuilder, networkService: AptosNetworkService) {
        self.transactionBuilder = transactionBuilder
        self.networkService = networkService
        super.init(wallet: wallet)
    }

    override func updateWalletManager() async throws {
        do {
            let accountInfo = try await networkService.getAccount(address: wallet.address).async()
            update(with: accountInfo)
        } catch {
            wallet.clearAmounts()
            wallet.clearPendingTransaction()
            throw error
        }
    }
}

extension AptosWalletManager: WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .getGasUnitPrice()
            .withWeakCaptureOf(self)
            .flatMap { walletManager, gasUnitPrice -> AnyPublisher<Fee, Error> in
                let expirationTimestamp = walletManager.createExpirationTimestampSecs()

                guard let transactionInfo = try? walletManager.transactionBuilder.buildToCalculateFee(
                    amount: amount,
                    destination: destination,
                    gasUnitPrice: gasUnitPrice,
                    expirationTimestamp: expirationTimestamp
                ) else {
                    return .anyFail(error: BlockchainSdkError.failedToGetFee)
                }

                return walletManager
                    .networkService
                    .calculateUsedGasPriceUnit(info: transactionInfo)
                    .withWeakCaptureOf(self)
                    .map { manager, info in
                        let decimalValue = info.value / manager.wallet.blockchain.decimalValue
                        let amount = Amount(with: manager.wallet.blockchain, value: decimalValue)

                        return Fee(
                            amount,
                            parameters: AptosFeeParams(
                                gasUnitPrice: info.params.gasUnitPrice,
                                maxGasAmount: info.params.maxGasAmount
                            )
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .map { estimatedFee -> [Fee] in
                [estimatedFee]
            }
            .eraseToAnyPublisher()
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let dataForSign: Data

        // This timestamp value must be synchronized between calls buildForSign / buildForSend
        let expirationTimestamp = createExpirationTimestampSecs()

        do {
            dataForSign = try transactionBuilder.buildForSign(transaction: transaction, expirationTimestamp: expirationTimestamp)
        } catch {
            return .sendTxFail(error: BlockchainSdkError.failedToBuildTx, currentHost: currentHost)
        }

        return signer
            .sign(hash: dataForSign, walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, signature -> AnyPublisher<String, Error> in
                guard let rawTransactionData = try? self.transactionBuilder.buildForSend(
                    transaction: transaction,
                    signature: signature,
                    expirationTimestamp: expirationTimestamp
                ) else {
                    return .anyFail(error: BlockchainSdkError.failedToSendTx)
                }

                return walletManager
                    .networkService
                    .submitTransaction(data: rawTransactionData)
                    .mapAndEraseSendTxError(tx: rawTransactionData.hex(), currentHost: walletManager.currentHost)
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionHash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionHash, currentProviderHost: walletManager.currentHost)
            }
            .mapSendTxError(currentHost: currentHost)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Implementation

private extension AptosWalletManager {
    func update(with accountModel: AptosAccountInfo) {
        wallet.add(coinValue: accountModel.balance / wallet.blockchain.decimalValue)

        if accountModel.sequenceNumber != transactionBuilder.currentSequenceNumber {
            wallet.clearPendingTransaction()
        }

        transactionBuilder.update(sequenceNumber: accountModel.sequenceNumber)
    }

    private func createExpirationTimestampSecs() -> UInt64 {
        UInt64(Date().addingTimeInterval(TimeInterval(Constants.transactionLifetimeInMin * 60)).timeIntervalSince1970)
    }
}

extension AptosWalletManager {
    enum Constants {
        static let transactionLifetimeInMin: Double = 5
    }
}
