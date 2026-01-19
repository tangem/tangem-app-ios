//
//  PolkadotWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import TangemSdk
import BigInt
import TangemFoundation
import TangemLocalization

class PolkadotWalletManager: BaseManager, WalletManager {
    private let network: PolkadotNetwork
    var txBuilder: PolkadotTransactionBuilder!
    var networkService: PolkadotNetworkService!

    var currentHost: String { networkService.host }

    init(network: PolkadotNetwork, wallet: Wallet) {
        self.network = network
        super.init(wallet: wallet)
    }

    override func updateWalletManager() async throws {
        let balance = try await networkService.getInfo(for: wallet.address).async()
        updateInfo(balance)
    }

    private func updateInfo(_ balance: BigUInt) {
        let decimals = wallet.blockchain.decimalCount
        guard
            let formatted = EthereumUtils.formatToPrecision(balance, numberDecimals: decimals, formattingDecimals: decimals, decimalSeparator: ".", fallbackToScientific: false),
            let value = Decimal(stringValue: formatted)
        else {
            return
        }

        wallet.add(amount: .init(with: wallet.blockchain, value: value))
        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension PolkadotWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Publishers.Zip(
            networkService.blockchainMeta(for: transaction.sourceAddress),
            networkService.getInfo(for: transaction.destinationAddress)
        )
        .flatMap { [weak self] meta, destinationBalance -> AnyPublisher<Data, Error> in
            guard let self = self else {
                return .emptyFail
            }

            let existentialDeposit = network.existentialDeposit
            if transaction.amount < existentialDeposit, destinationBalance == BigUInt(0) {
                let message = Localization.noAccountPolkadot(existentialDeposit.string(roundingMode: .plain))
                return Fail(error: BlockchainSdkError.noAccount(message: message, amountToCreate: existentialDeposit.value)).eraseToAnyPublisher()
            }

            return sign(amount: transaction.amount, destination: transaction.destinationAddress, meta: meta, signer: signer)
        }
        .flatMap { [weak self] image -> AnyPublisher<String, Error> in
            guard let self = self else {
                return .emptyFail
            }
            return networkService
                .submitExtrinsic(data: image)
                .mapAndEraseSendTxError(tx: image.hex())
                .eraseToAnyPublisher()
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, hash in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
            manager.wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: hash, currentProviderHost: manager.currentHost)
        }
        .mapSendTxError()
        .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService
            .blockchainMeta(for: destination)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, meta in
                walletManager.sign(amount: amount, destination: destination, meta: meta, signer: Ed25519DummyTransactionSigner())
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, image in
                walletManager.networkService.fee(for: image).map { $0.partialFee }
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, bigUIntValue in
                guard let feeDecimalValue = bigUIntValue.decimal else {
                    throw BlockchainSdkError.failedToGetFee
                }

                let feeAmount = Amount(
                    with: walletManager.wallet.blockchain,
                    value: feeDecimalValue / walletManager.wallet.blockchain.decimalValue
                )

                return [Fee(feeAmount)]
            }
            .eraseToAnyPublisher()
    }

    private func sign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signer: TransactionSigner) -> AnyPublisher<Data, Error> {
        let wallet = wallet
        return Just(())
            .tryMap { [weak self] _ in
                guard let self = self else {
                    throw BlockchainSdkError.empty
                }
                return try txBuilder.buildForSign(
                    amount: amount,
                    destination: destination,
                    meta: meta
                )
            }
            .flatMap { preImage in
                signer.sign(
                    hash: preImage,
                    walletPublicKey: wallet.publicKey
                )
            }
            .tryMap { [weak self] signature in
                guard let self = self else {
                    throw BlockchainSdkError.empty
                }
                return try txBuilder.buildForSend(
                    amount: amount,
                    destination: destination,
                    meta: meta,
                    signature: signature
                )
            }
            .eraseToAnyPublisher()
    }
}

extension PolkadotWalletManager: ExistentialDepositProvider {
    var existentialDeposit: Amount {
        network.existentialDeposit
    }
}

extension PolkadotWalletManager: MinimumBalanceRestrictable {
    var minimumBalance: Amount {
        network.existentialDeposit
    }
}

extension PolkadotWalletManager: MinimalBalanceProvider {
    func minimalBalance() -> Decimal {
        minimumBalance.value
    }
}

extension PolkadotWalletManager: ThenProcessable {}

// MARK: - Dummy transaction signer

private class Ed25519DummyTransactionSigner: TransactionSigner {
    private let privateKey = Data(repeating: 0, count: 32)

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: BlockchainSdkError.empty).eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        Just<Data>(hash)
            .tryMap { hash in
                let signature = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).signature(for: hash)
                return SignatureInfo(signature: signature, publicKey: walletPublicKey.blockchainKey, hash: hash)
            }
            .eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: BlockchainSdkError.failedToGetFee).eraseToAnyPublisher()
    }
}
