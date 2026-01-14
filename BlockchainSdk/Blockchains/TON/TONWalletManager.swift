//
//  TONWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import WalletCore

final class TONWalletManager: BaseManager, WalletManager {
    // MARK: - Properties

    var currentHost: String { networkService.host }

    // MARK: - Private Properties

    private let networkService: TONNetworkService
    private let transactionBuilder: TONTransactionBuilder
    private var jettonWalletAddressCache: [Token: String] = [:]

    // MARK: - Init

    init(wallet: Wallet, transactionBuilder: TONTransactionBuilder, networkService: TONNetworkService) throws {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Implementation

    override func updateWalletManager() async throws {
        do {
            let info = try await networkService.getInfo(address: wallet.address, tokens: cardTokens).async()
            await update(with: info)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        getJettonWalletAddressIfNeeded(for: transaction.sourceAddress, transactionType: transaction.amount.type)
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] jettonWalletAddress -> (TONTransactionInput, Data) in
                guard let self else {
                    throw BlockchainSdkError.failedToBuildTx
                }

                let params = transaction.params as? TONTransactionParams

                let buildInput = TONTransactionInput(
                    amount: transaction.amount,
                    destination: transaction.destinationAddress,
                    expireAt: createExpirationTimestampSecs(),
                    jettonWalletAddress: jettonWalletAddress,
                    params: params
                )

                let hashForSign = try transactionBuilder.buildForSign(buildInput: buildInput)

                return (buildInput, hashForSign)
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, input in
                let (buildInput, hash) = input

                return signer.sign(hash: hash, walletPublicKey: manager.wallet.publicKey)
                    .map { ($0.signature, buildInput) }
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input -> String in
                let (signature, buildInput) = input

                let dataForSend = try walletManager.transactionBuilder.buildForSend(
                    buildInput: buildInput,
                    signature: signature
                )

                return dataForSend
            }
            .flatMap { [weak self] message -> AnyPublisher<String, Error> in
                guard let self else {
                    return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
                }

                return networkService
                    .send(message: message)
                    .mapAndEraseSendTxError(tx: message)
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { manager, base64String in
                let mapper = PendingTransactionRecordMapper()
                let hex = Data(base64Encoded: base64String)?.hex() ?? ""
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hex)
                manager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hex, currentProviderHost: manager.currentHost)
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionFeeProvider

extension TONWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        getJettonWalletAddressIfNeeded(transactionType: amount.type)
            .tryMap { [weak self] jettonWalletAddress -> String in
                guard let self else {
                    throw BlockchainSdkError.failedToBuildTx
                }

                let buildInput = TONTransactionInput(
                    amount: amount,
                    destination: destination,
                    expireAt: createExpirationTimestampSecs(),
                    jettonWalletAddress: jettonWalletAddress,
                    params: nil
                )

                let buildForSend = try transactionBuilder.buildForSend(
                    buildInput: buildInput,
                    signature: Data(repeating: 0, count: 64)
                )

                return buildForSend
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, message -> AnyPublisher<([Fee], String?), Error> in
                manager.networkService.getFee(
                    source: manager.wallet.address,
                    destination: destination,
                    amount: amount,
                    message: message
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, feesAndAddress -> AnyPublisher<[Fee], Error> in
                manager.transformFeeIfNeeded(with: feesAndAddress, amount: amount)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Implementation

private extension TONWalletManager {
    private func update(with info: TONWalletInfo) async {
        if info.sequenceNumber != transactionBuilder.sequenceNumber {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: info.balance)

        for (token, tokenInfo) in info.tokensInfo {
            switch tokenInfo {
            case .success(let value):
                wallet.add(tokenValue: value.balance, for: token)
                // jetton wallet address is used to calculate fee and build transaction
                jettonWalletAddressCache[token] = value.jettonWalletAddress
            case .failure:
                wallet.clearAmount(for: token)
                jettonWalletAddressCache[token] = nil
            }
        }

        transactionBuilder.sequenceNumber = info.sequenceNumber
    }

    private func getJettonWalletAddressIfNeeded(
        for ownerAddress: String? = nil,
        transactionType: Amount.AmountType
    ) -> AnyPublisher<String?, Error> {
        let ownerAddress = ownerAddress ?? defaultSourceAddress
        switch transactionType {
        case .coin, .reserve, .feeResource:
            return .justWithError(output: nil)
        case .token(let token):
            guard let cachedJettonWalletAddress = jettonWalletAddressCache[token] else {
                return networkService.getJettonWalletAddress(for: ownerAddress, token: token)
                    .map { .some($0) }
                    .eraseToAnyPublisher()
            }
            return .justWithError(output: cachedJettonWalletAddress)
        }
    }

    private func transformFeeIfNeeded(with feesAndAddress: ([Fee], String?), amount: Amount) -> AnyPublisher<[Fee], Error> {
        let (fees, recipientJettonWalletAddress) = feesAndAddress

        // Check if recipient's jetton wallet is active
        if let recipientJettonWalletAddress {
            return networkService.isJettonWalletActive(jettonWalletAddress: recipientJettonWalletAddress)
                .withWeakCaptureOf(self)
                .map { manager, isActive in
                    manager.appendJettonTransferProcessingFeeIfNeeded(
                        fees,
                        amountType: amount.type,
                        isRecipientJettonWalletActive: isActive
                    )
                }
                .eraseToAnyPublisher()
        } else {
            let updatedFees = appendJettonTransferProcessingFeeIfNeeded(
                fees,
                amountType: amount.type,
                isRecipientJettonWalletActive: false
            )
            return Just(updatedFees)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    private func appendJettonTransferProcessingFeeIfNeeded(
        _ fees: [Fee],
        amountType: Amount.AmountType,
        isRecipientJettonWalletActive: Bool
    ) -> [Fee] {
        guard case .token = amountType else {
            return fees
        }

        let processingFee = isRecipientJettonWalletActive
            ? TONTransactionBuilder.Constants.jettonTransferProcessingFeeForActiveWallet
            : TONTransactionBuilder.Constants.jettonTransferProcessingFee

        return fees.map { fee in
            var amount = fee.amount
            amount.value += processingFee
            return Fee(amount, parameters: fee.parameters)
        }
    }

    private func createExpirationTimestampSecs() -> UInt32 {
        UInt32(Date().addingTimeInterval(Constants.transactionLifetimeInSec).timeIntervalSince1970)
    }
}

private extension TONWalletManager {
    enum Constants {
        static let transactionLifetimeInSec: TimeInterval = 60
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension TONWalletManager: StakeKitTransactionSender, StakingTransactionsBuilder {
    typealias RawTransaction = String

    /// we need to pass the same signing input into prepareForSend method
    func buildRawTransactions<T: StakingTransaction>(
        from transactions: [T],
        publicKey: Wallet.PublicKey,
        signer: any TransactionSigner
    ) async throws -> [String] {
        guard let transactions = transactions as? [StakeKitTransaction] else {
            throw BlockchainSdkError.failedToBuildTx
        }
        let expireAt = createExpirationTimestampSecs()

        let helper = TONStakeKitTransactionHelper(transactionBuilder: transactionBuilder)

        let preSignData = try transactions.map {
            try helper.prepareForSign($0, expireAt: expireAt)
        }

        let signatures: [SignatureInfo] = try await signer.sign(
            hashes: preSignData.map(\.dataToSign),
            walletPublicKey: publicKey
        ).async()

        return try signatures.enumerated().compactMap { index, signature -> RawTransaction? in
            guard let preSignData = preSignData[safe: index] else { return nil }
            return try helper.prepareForSend(
                preSignData: preSignData,
                signatureInfo: signature
            )
        }
    }
}

extension TONWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(rawTransaction: RawTransaction) async throws -> String {
        try await networkService.send(message: rawTransaction).async()
    }
}

extension TONWalletManager: BlockchainAccountInitializationService {
    func isAccountInitialized() async throws -> Bool {
        try await TONStakingAccountInitializationStateProvider(
            address: wallet.address,
            networkService: networkService
        ).isAccountInitialized()
    }

    func estimateInitializationFee() async throws -> Fee {
        let fees = try await getFee(amount: initializationAmount, destination: wallet.address).async()

        guard let fee = fees.first else {
            throw BlockchainSdkError.failedToGetFee
        }

        return fee
    }

    func initializationTransaction(fee: Fee) -> Transaction {
        Transaction(
            amount: initializationAmount,
            fee: fee,
            sourceAddress: wallet.address,
            destinationAddress: wallet.address,
            changeAddress: wallet.address
        )
    }

    private var initializationAmount: Amount {
        Amount(with: wallet.blockchain, value: 1)
    }
}
