//
//  FilecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class FilecoinWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    private let networkService: FilecoinNetworkService
    private let transactionBuilder: FilecoinTransactionBuilder

    private var nonce: UInt64 = 0

    init(
        wallet: Wallet,
        networkService: FilecoinNetworkService,
        transactionBuilder: FilecoinTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    override func updateWalletManager() async throws {
        do {
            let accountInfo = try await networkService
                .getAccountInfo(address: wallet.address)
                .async()

            update(accountInfo: accountInfo)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func update(accountInfo: FilecoinAccountInfo) {
        if accountInfo.nonce != nonce {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: accountInfo.balance / wallet.blockchain.decimalValue)
        nonce = accountInfo.nonce
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        guard let bigUIntValue = amount.bigUIntValue else {
            return .anyFail(error: BlockchainSdkError.failedToGetFee)
        }

        return networkService
            .getAccountInfo(address: wallet.address)
            .map { [address = wallet.address] accountInfo in
                FilecoinMessage(
                    from: address,
                    to: destination,
                    value: String(bigUIntValue, radix: 10),
                    nonce: accountInfo.nonce,
                    gasLimit: nil,
                    gasFeeCap: nil,
                    gasPremium: nil
                )
            }
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, message in
                networkService.getEstimateMessageGas(message: message)
            }
            .withWeakCaptureOf(self)
            .tryMap { (walletManager: FilecoinWalletManager, gasInfo) -> [Fee] in
                guard let gasFeeCapDecimal = Decimal(stringValue: gasInfo.gasFeeCap) else {
                    throw BlockchainSdkError.failedToGetFee
                }

                let gasLimitDecimal = Decimal(gasInfo.gasLimit)

                return [
                    Fee(
                        Amount(
                            with: .filecoin,
                            type: .coin,
                            value: gasLimitDecimal * gasFeeCapDecimal / walletManager.wallet.blockchain.decimalValue
                        ),
                        parameters: FilecoinFeeParameters(
                            gasLimit: gasInfo.gasLimit,
                            gasFeeCap: BigUInt(stringLiteral: gasInfo.gasFeeCap),
                            gasPremium: BigUInt(stringLiteral: gasInfo.gasPremium)
                        )
                    ),
                ]
            }
            .eraseToAnyPublisher()
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        networkService
            .getAccountInfo(address: wallet.address)
            .withWeakCaptureOf(transactionBuilder)
            .tryMap { transactionBuilder, accountInfo in
                let hashToSign = try transactionBuilder.buildForSign(
                    transaction: transaction,
                    nonce: accountInfo.nonce
                )
                return (hashToSign, accountInfo.nonce)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, args in
                let (hashToSign, nonce) = args
                return signer
                    .sign(hash: hashToSign, walletPublicKey: walletManager.wallet.publicKey)
                    .withWeakCaptureOf(walletManager)
                    .tryMap { walletManager, signature in
                        try walletManager.transactionBuilder.buildForSend(
                            transaction: transaction,
                            nonce: nonce,
                            signatureInfo: SignatureInfo(
                                signature: signature,
                                publicKey: walletManager.wallet.publicKey.blockchainKey,
                                hash: hashToSign
                            )
                        )
                    }
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, message in
                walletManager.networkService
                    .submitTransaction(signedMessage: message)
                    .mapAndEraseSendTxError(tx: try? JSONEncoder().encode(message).utf8String)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, txId in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: txId, currentProviderHost: walletManager.currentHost)
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }
}
