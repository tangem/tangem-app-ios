//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya

class EthereumWalletManager: BaseManager, WalletManager, EthereumTransactionSigner {
    let txBuilder: EthereumTransactionBuilder
    let networkService: EthereumNetworkService
    let addressConverter: EthereumAddressConverter
    let yieldSupplyService: YieldSupplyService?
    let allowsFeeSelection: Bool

    var currentHost: String { networkService.host }

    init(
        wallet: Wallet,
        addressConverter: EthereumAddressConverter,
        txBuilder: EthereumTransactionBuilder,
        networkService: EthereumNetworkService,
        yieldSupplyService: YieldSupplyService? = nil,
        allowsFeeSelection: Bool
    ) {
        self.txBuilder = txBuilder
        self.networkService = networkService
        self.addressConverter = addressConverter
        self.yieldSupplyService = yieldSupplyService
        self.allowsFeeSelection = allowsFeeSelection

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = addressConverter.convertToETHAddressPublisher(wallet.address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                Publishers.Zip(
                    walletManager.networkService
                        .getInfo(
                            address: convertedAddress,
                            tokens: walletManager.cardTokens,
                        ),
                    walletManager
                        .getYieldBalances(
                            address: convertedAddress,
                            tokens: walletManager.cardTokens
                        )
                )
            }
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case .failure(let error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response.0, yieldTokensBalances: response.1)
                completion(.success(()))
            })
    }

    /// It can't be into extension because it will be overridden in the `OptimismWalletManager`
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        let fromPublisher = addressConverter.convertToETHAddressPublisher(defaultSourceAddress)
        let destinationPublisher = addressConverter.convertToETHAddressPublisher(destination)

        return fromPublisher
            .zip(destinationPublisher)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddresses -> AnyPublisher<[Fee], Error> in
                let (from, destination) = convertedAddresses
                if walletManager.wallet.blockchain.supportsEIP1559 {
                    return walletManager.getEIP1559Fee(from: from, destination: destination, value: value, data: data)
                } else {
                    return walletManager.getLegacyFee(from: from, destination: destination, value: value, data: data)
                }
            }
            .eraseToAnyPublisher()
    }

    /// It can't be into extension because it will be overridden in the `MantleWalletManager`
    /// Build and sign transaction
    /// - Parameters:
    /// - Returns: The hex of the raw transaction ready to be sent over the network
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        let noncePublisher: AnyPublisher<Int, Error> =
            (transaction.fee.parameters as? EthereumFeeParameters)?
                .nonce
                .map { Just($0).setFailureType(to: Error.self).eraseToAnyPublisher() }
                ?? networkService.getPendingTxCount(transaction.sourceAddress)

        return Publishers.Zip(addressConverter.convertToETHAddressesPublisher(in: transaction), noncePublisher)
            .map { convertedTransaction, nonce in
                convertedTransaction.then { convertedTransaction in
                    let ethParams = convertedTransaction.params as? EthereumTransactionParams
                    convertedTransaction.params = ethParams?.with(nonce: nonce) ?? EthereumTransactionParams(nonce: nonce)
                }
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedTransaction in
                Result {
                    try walletManager.txBuilder.buildForSign(transaction: convertedTransaction)
                }
                .publisher
                .withWeakCaptureOf(walletManager)
                .flatMap { walletManager, hashToSign in
                    signer.sign(hash: hashToSign, walletPublicKey: walletManager.wallet.publicKey)
                }
                .withWeakCaptureOf(walletManager)
                .tryMap { walletManager, signatureInfo -> String in
                    try walletManager.txBuilder
                        .buildForSend(
                            transaction: convertedTransaction,
                            signatureInfo: signatureInfo
                        )
                        .hex()
                        .addHexPrefix()
                }
            }
            .eraseToAnyPublisher()
    }

    func signMultiple(_ transactions: [Transaction], signer: TransactionSigner) -> AnyPublisher<[String], Error> {
        guard let firstTransaction = transactions.first else {
            return .justWithError(output: []).eraseToAnyPublisher()
        }

        return networkService.getPendingTxCount(firstTransaction.sourceAddress)
            .asyncMap { [addressConverter, txBuilder, wallet] pendingNonce in
                let enrichedTransactions = try transactions.enumerated().map { index, transaction in
                    let convertedTransaction = try addressConverter.convertToETHAddresses(in: transaction)
                    return Self.enrichTransactionWithNonce(
                        transaction: convertedTransaction,
                        pendingNonce: pendingNonce + index
                    )
                }

                let hashesToSign = try enrichedTransactions.map {
                    try txBuilder.buildForSign(transaction: $0)
                }

                let signatures = try await signer.sign(hashes: hashesToSign, walletPublicKey: wallet.publicKey).async()

                return try zip(signatures, enrichedTransactions).map { signatureInfo, transaction in
                    try txBuilder.buildForSend(
                        transaction: transaction,
                        signatureInfo: signatureInfo
                    )
                    .hex()
                    .addHexPrefix()
                }
            }
            .eraseToAnyPublisher()
    }

    /// It can't be into extension because it will be overridden in the `MantleWalletManager`
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        let toPublisher = addressConverter.convertToETHAddressPublisher(to)
        let fromPublisher = addressConverter.convertToETHAddressPublisher(from)

        return toPublisher
            .zip(fromPublisher)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddresses in
                let (to, from) = convertedAddresses
                return walletManager.networkService
                    .getGasLimit(to: to, from: from, value: value, data: data)
            }
            .eraseToAnyPublisher()
    }

    private func getYieldBalances(
        address: String,
        tokens: [Token]
    ) -> AnyPublisher<[Token: Result<Amount, Error>], Error> {
        Future.async { [yieldSupplyService] in
            guard let yieldSupplyService else { return [:] }

            return await yieldSupplyService.getBalances(address: address, tokens: tokens)
        }
        .eraseToAnyPublisher()
    }

    private static func enrichTransactionWithNonce(transaction: Transaction, pendingNonce: Int) -> Transaction {
        let userNonce = (transaction.fee.parameters as? EthereumFeeParameters)?.nonce

        let nonce: Int

        if let userNonce, userNonce < pendingNonce {
            nonce = userNonce
        } else {
            nonce = pendingNonce
        }

        var mutableTransaction = transaction
        let ethParams = mutableTransaction.params as? EthereumTransactionParams
        mutableTransaction.params = ethParams?.with(nonce: nonce) ?? EthereumTransactionParams(nonce: nonce)
        return mutableTransaction
    }

    /// Amounts that are inside 'wallet.amounts' may contain additional info about yield module status.
    /// When estimating fee or sending a transaction, we need get this additional info in order to
    /// use correct smart contract method.
    private static func sanitizeAmount(_ amount: Amount, wallet: Wallet) -> Amount {
        if case .token = amount.type, let sanitizedAmount = wallet.amounts[amount.type] {
            return Amount(
                with: wallet.blockchain,
                type: sanitizedAmount.type,
                value: amount.value
            )
        } else {
            return amount
        }
    }

    private static func sanitizeTransaction(_ transaction: Transaction, wallet: Wallet) -> Transaction {
        transaction.withAmount(sanitizeAmount(transaction.amount, wallet: wallet))
    }
}

// MARK: - EthereumNetworkProvider

extension EthereumWalletManager: EthereumNetworkProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        getAllowanceRaw(owner: owner, spender: spender, contractAddress: contractAddress)
            .tryMap { response in
                if let allowance = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) {
                    return allowance
                }

                throw ETHError.failedToParseAllowance
            }
            .eraseToAnyPublisher()
    }

    func getAllowanceRaw(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error> {
        let ownerPublisher = addressConverter.convertToETHAddressPublisher(owner)
        let spenderPublisher = addressConverter.convertToETHAddressPublisher(spender)
        let contractAddressPublisher = addressConverter.convertToETHAddressPublisher(contractAddress)

        return ownerPublisher
            .zip(spenderPublisher, contractAddressPublisher)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddresses in
                let (owner, spender, contractAddress) = convertedAddresses
                return walletManager.networkService.getAllowance(owner: owner, spender: spender, contractAddress: contractAddress)
            }
            .eraseToAnyPublisher()
    }

    // Balance

    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getBalance(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    // Nonce

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getTxCount(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getPendingTxCount(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    // Fee

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        networkService.getFeeHistory()
    }
}

// MARK: - Private

private extension EthereumWalletManager {
    func getEIP1559Fee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getEIP1559Fee(
            to: destination,
            from: from,
            value: value,
            data: data?.hex().addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.mapEIP1559Fee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func mapEIP1559Fee(response: EthereumEIP1559FeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.low.max,
                priorityFee: response.fees.low.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.market.max,
                priorityFee: response.fees.market.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.fast.max,
                priorityFee: response.fees.fast.priority
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func getLegacyFee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getLegacyFee(
            to: destination,
            from: from,
            value: value,
            data: data?.hex().addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.mapLegacyFee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func mapLegacyFee(response: EthereumLegacyFeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.lowGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.marketGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.fastGasPrice
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func updateWallet(with response: EthereumInfoResponse, yieldTokensBalances: [Token: Result<Amount, Error>]) {
        wallet.add(coinValue: response.balance)

        for tokenBalance in response.tokenBalances {
            switch (yieldTokensBalances[tokenBalance.key], tokenBalance.value) {
            case (.success(let amount), _):
                wallet.add(amount: amount)
            case (.failure, _), (.none, .failure):
                wallet.clearAmount(for: tokenBalance.key)
            case (.none, .success(let value)):
                wallet.add(tokenValue: value, for: tokenBalance.key)
            }
        }

        if response.txCount == response.pendingTxCount {
            wallet.clearPendingTransaction()
        } else if response.pendingTxs.isEmpty {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction()
            response.pendingTxs.forEach {
                let mapper = PendingTransactionRecordMapper()
                let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                wallet.addPendingTransaction(transaction)
            }
        }
    }
}

// MARK: - TransactionFeeProvider

extension EthereumWalletManager: TransactionFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        addressConverter.convertToETHAddressPublisher(destination)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedDestination -> AnyPublisher<[Fee], Error> in
                let sanitizedAmount = Self.sanitizeAmount(amount, wallet: walletManager.wallet)
                switch sanitizedAmount.type {
                case .coin:
                    guard let hexAmount = sanitizedAmount.encodedForSend else {
                        return .anyFail(error: BlockchainSdkError.failedToLoadFee)
                    }

                    return walletManager.getFee(destination: convertedDestination, value: hexAmount, data: nil)
                case .token(let token):
                    do {
                        let transferData = try walletManager.buildForTokenTransfer(
                            destination: convertedDestination,
                            amount: sanitizedAmount
                        )

                        let contractAddress = token.metadata.yieldSupply.flatMap { $0.yieldContractAddress } ?? token.contractAddress
                        return walletManager.getFee(destination: contractAddress, value: nil, data: transferData)
                    } catch {
                        return .anyFail(error: error)
                    }
                case .reserve, .feeResource:
                    return .anyFail(error: BlockchainSdkError.notImplemented)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionSender

extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sanitizedTransaction = Self.sanitizeTransaction(transaction, wallet: wallet)
        return addressConverter.convertToETHAddressesPublisher(in: sanitizedTransaction)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedTransaction in
                walletManager.sign(convertedTransaction, signer: signer)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransaction in
                walletManager.networkService.send(transaction: rawTransaction)
                    .mapAndEraseSendTxError(tx: rawTransaction)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: sanitizedTransaction, hash: hash)
                walletManager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash, currentProviderHost: walletManager.currentHost)
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }
}

// MARK: - MultipleTransactionSender

extension EthereumWalletManager: MultipleTransactionsSender {
    func send(_ transactions: [Transaction], signer: any TransactionSigner) -> AnyPublisher<[TransactionSendResult], SendTxError> {
        let sanitizedTransactions = transactions.map { Self.sanitizeTransaction($0, wallet: wallet) }
        return signMultiple(sanitizedTransactions, signer: signer)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, rawTransactions in
                var results: [TransactionSendResult] = []
                for (transaction, rawTransaction) in zip(transactions, rawTransactions) {
                    let hash = try await walletManager.networkService
                        .send(transaction: rawTransaction)
                        .async()

                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    walletManager.wallet.addPendingTransaction(record)

                    results.append(TransactionSendResult(hash: hash, currentProviderHost: walletManager.currentHost))
                }

                return results
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionValidator

extension EthereumWalletManager: TransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        // This wallet manager still ignores `destination` parameter even in the custom implementation of this method
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")

        switch amount.type.token?.metadata.kind {
        case .fungible, .none:
            // Just calling the default implementation for the `TransactionValidator.validate(amount:fee:)` method
            try validateAmounts(amount: amount, fee: fee.amount)
        case .nonFungible:
            // We can't validate amounts for non-fungible tokens, therefore performing only the fee validation
            try validate(fee: fee.amount)
        }
    }
}

// MARK: - EthereumTransactionDataBuilder

extension EthereumWalletManager: EthereumTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Decimal) throws -> Data {
        let spender = try addressConverter.convertToETHAddress(spender)
        return txBuilder.buildForApprove(spender: spender, amount: amount)
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        let destination = try addressConverter.convertToETHAddress(destination)
        return try txBuilder.buildForTokenTransfer(destination: destination, amount: amount)
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension EthereumWalletManager: StakeKitTransactionsBuilder, StakeKitTransactionSender, StakeKitTransactionDataProvider {
    typealias RawTransaction = String

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try EthereumStakeKitTransactionHelper(transactionBuilder: txBuilder).prepareForSign(transaction)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        try EthereumStakeKitTransactionHelper(transactionBuilder: txBuilder)
            .prepareForSend(stakingTransaction: transaction, signatureInfo: signature)
            .hex()
            .addHexPrefix()
    }
}

// MARK: - StakeKitTransactionDataBroadcaster

extension EthereumWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.send(transaction: rawTransaction).async()
    }
}

// MARK: - YieldsServiceProvider

extension EthereumWalletManager: YieldSupplyServiceProvider {}
