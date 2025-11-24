//
//  KaspaWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemLocalization

final class KaspaWalletManager: BaseManager, WalletManager {
    private typealias IncompleteTokenTransactionsInMemoryStorage = ThreadSafeContainer<
        [KaspaIncompleteTokenTransactionStorageID: KaspaKRC20.IncompleteTokenTransactionParams]
    >

    private let networkService: KaspaNetworkService
    private let networkServiceKRC20: KaspaNetworkServiceKRC20
    private let txBuilder: KaspaTransactionBuilder
    private let unspentOutputManager: UnspentOutputManager
    private let dataStorage: BlockchainDataStorage
    private var incompleteTokenTransactionsInMemoryStorage: IncompleteTokenTransactionsInMemoryStorage = [:]
    private var lastLoadedCardTokens: [Token] = []
    private var pendingTokenTransactionHashes: [Token: Set<String>] = [:]

    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }

    // MARK: - Initialization/Deinitialization

    init(
        wallet: Wallet,
        networkService: KaspaNetworkService,
        networkServiceKRC20: KaspaNetworkServiceKRC20,
        txBuilder: KaspaTransactionBuilder,
        unspentOutputManager: UnspentOutputManager,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.networkServiceKRC20 = networkServiceKRC20
        self.txBuilder = txBuilder
        self.unspentOutputManager = unspentOutputManager
        self.dataStorage = dataStorage

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = loadCachedIncompleteTokenTransactionsIfNeeded()
            .withWeakCaptureOf(self)
            .flatMap { manager, _ in
                let coinResponse = manager.networkService.getInfo(address: manager.wallet.address)
                let tokenResponse = manager.networkServiceKRC20.balance(
                    address: manager.wallet.address,
                    tokens: manager.cardTokens
                )

                return Publishers.Zip(coinResponse, tokenResponse)
            }
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { [weak self] kaspaAddressInfo, kaspaTokensInfo in
                self?.updateWallet(kaspaAddressInfo, tokensInfo: kaspaTokensInfo)
                completion(.success(()))
            })
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let amountType = transaction.amount.type

        switch amountType {
        case .token(let token) where transaction.params is KaspaKRC20.IncompleteTokenTransactionParams:
            return sendKaspaRevealTokenTransaction(transaction, token: token, signer: signer)
        case .token(let token):
            let comparator = KaspaKRC20.IncompleteTokenTransactionComparator()

            // This `sendIncompleteKaspaTokenTransactionIfPossible` call attempts to re-send a cached incomplete
            // token transaction (if one exists).
            // Errors in searching, mapping, and building a new transaction from this cached incomplete transaction will
            // result in sending a completely new token transaction (created from scratch) within the `tryCatch` block below.
            return sendIncompleteKaspaTokenTransactionIfPossible(
                for: amountType,
                signer: signer,
                validator: { comparator.isIncompleteTokenTransaction($0, equalTo: transaction) }
            )
            .tryCatch { [weak self] sendTxError in
                guard
                    let self,
                    let underlyingError = sendTxError.error as? KaspaKRC20.Error
                else {
                    // Re-throw original error since we want to handle only `KaspaKRC20.Error` here
                    throw sendTxError
                }

                switch underlyingError {
                case .unableToFindIncompleteTokenTransaction,
                     .invalidIncompleteTokenTransaction,
                     .unableToBuildRevealTransaction:
                    return sendKaspaTokenTransaction(transaction, token: token, signer: signer)
                }
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
        case .coin:
            return sendKaspaCoinTransaction(transaction, signer: signer)
        case .reserve,
             .feeResource:
            // Not supported
            return .anyFail(error: SendTxError(error: BlockchainSdkError.notImplemented))
        }
    }

    private func sendKaspaCoinTransaction(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Future.async {
            try await self.txBuilder.buildForSign(transaction: transaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, input in
            signer.sign(hashes: input.hashes, walletPublicKey: manager.wallet.publicKey)
                .map { ($0, input) }
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, input in
            let (signatures, result) = input
            return manager.txBuilder.mapToTransaction(transaction: result.transaction, signatures: signatures)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, tx in
            let encodedRawTransactionData = try? JSONEncoder().encode(tx)

            return manager
                .networkService
                .send(transaction: KaspaDTO.Send.Request(transaction: tx))
                .mapAndEraseSendTxError(tx: encodedRawTransactionData?.hexString.lowercased())
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { manager, response in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: response.transactionId)
            manager.wallet.addPendingTransaction(record)
        })
        .map { manager, response in
            return TransactionSendResult(hash: response.transactionId, currentProviderHost: manager.currentHost)
        }
        .mapSendTxError()
        .eraseToAnyPublisher()
    }

    private func sendKaspaTokenTransaction(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Future.async {
            try await self.txBuilder.buildForSignKRC20(transaction: transaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, input in
            let (txgroup, _) = input
            let hashes = txgroup.hashesCommit + txgroup.hashesReveal
            return signer
                .sign(hashes: hashes, walletPublicKey: manager.wallet.publicKey)
                .map { ($0.map(\.signature), input) }
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, input in
            let (signatures, result) = input

            // Build Commit & Reveal
            let commitSignatures = Array(signatures[..<result.txgroup.hashesCommit.count])
            let revealSignatures = Array(signatures[result.txgroup.hashesCommit.count...])

            let commitTx = manager.txBuilder.mapToTransaction(
                transaction: result.txgroup.kaspaCommitTransaction,
                signatures: commitSignatures
            )

            let revealTx = manager.txBuilder.mapToRevealTransaction(
                transaction: result.txgroup.kaspaRevealTransaction,
                commitRedeemScript: result.meta.redeemScriptCommit.data,
                signatures: revealSignatures
            )

            return (commitTx, revealTx, result)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, input in
            // Send Commit
            let (commitTx, revealTx, result) = input
            let encodedRawTransactionData = try? JSONEncoder().encode(commitTx)

            return manager.networkService
                .send(transaction: KaspaDTO.Send.Request(transaction: commitTx))
                .mapAndEraseSendTxError(tx: encodedRawTransactionData?.hexString.lowercased())
                .mapToValue((revealTx, result))
        }
        .withWeakCaptureOf(self)
        .asyncMap { manager, input in
            let (revealTx, result) = input
            // Store Commit
            await manager.store(incompleteTokenTransaction: result.meta.incompleteTransactionParams, for: token)
            return revealTx
        }
        .delay(for: .seconds(KaspaKRC20.Constants.revealTransactionSendDelay), scheduler: DispatchQueue.main)
        .withWeakCaptureOf(self)
        .flatMap { manager, revealTx in
            // Send Reveal
            let encodedRawTransactionData = try? JSONEncoder().encode(revealTx)

            return manager
                .networkService
                .send(transaction: KaspaDTO.Send.Request(transaction: revealTx))
                .handleEvents(receiveFailure: { [weak manager] _ in
                    // A failed reveal tx should trigger `wallet` update so the SDK consumer
                    // can observe and handle it (e.g. display a notification)
                    manager?.wallet.setAssetRequirements()
                })
                .wire { [weak manager] () -> AnyPublisher<Void, Error> in
                    guard let manager else {
                        return .anyFail(error: BlockchainSdkError.empty)
                    }

                    // Both failed and successful reveal txs should trigger the update of the UTXOs state in tx builder,
                    // therefore `wire` operator is used here
                    return manager.updateUnspentOutputs()
                }
                .mapAndEraseSendTxError(tx: encodedRawTransactionData?.hexString.lowercased())
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { manager, response in
            manager.handleSuccessfulRevealTokenTransaction(transaction, token: token, response: response)
        })
        .asyncMap { manager, response in
            // Delete Commit
            await manager.removeIncompleteTokenTransaction(for: token)
            return TransactionSendResult(hash: response.transactionId, currentProviderHost: manager.currentHost)
        }
        .mapSendTxError()
        .eraseToAnyPublisher()
    }

    private func sendIncompleteKaspaTokenTransactionIfPossible(
        for asset: Asset,
        signer: any TransactionSigner,
        validator isIncompleteTokenTransactionValid: @escaping (_ tx: KaspaKRC20.IncompleteTokenTransactionParams) -> Bool
    ) -> some Publisher<TransactionSendResult, SendTxError> {
        return Just(asset)
            .withWeakCaptureOf(self)
            .tryMap { manager, asset in
                guard let token = asset.token,
                      let incompleteTokenTransaction = manager.getIncompleteTokenTransaction(for: asset) else {
                    throw KaspaKRC20.Error.unableToFindIncompleteTokenTransaction
                }

                guard isIncompleteTokenTransactionValid(incompleteTokenTransaction) else {
                    throw KaspaKRC20.Error.invalidIncompleteTokenTransaction
                }

                guard let tokenTransaction = manager.makeTransaction(from: incompleteTokenTransaction, for: token) else {
                    throw KaspaKRC20.Error.unableToBuildRevealTransaction
                }

                return tokenTransaction
            }
            .mapSendTxError()
            .withWeakCaptureOf(self)
            .flatMap { manager, tokenTransaction in
                return manager.send(tokenTransaction, signer: signer)
            }
    }

    private func sendKaspaRevealTokenTransaction(
        _ transaction: Transaction,
        token: Token,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let kaspaTransaction: KaspaTransaction
        let commitRedeemScript: KaspaKRC20.RedeemScript
        let hashes: [Data]

        guard let params = transaction.params as? KaspaKRC20.IncompleteTokenTransactionParams,
              // Here, we use fee, which is obtained from previously saved data and the hardcoded dust value
              let feeParams = transaction.fee.parameters as? KaspaKRC20.TokenTransactionFeeParams
        else {
            return .sendTxFail(error: BlockchainSdkError.failedToBuildTx)
        }

        do {
            let result = try txBuilder.buildForSignRevealTransactionKRC20(
                sourceAddress: transaction.sourceAddress,
                params: params,
                fee: Fee(feeParams.revealFee)
            )

            kaspaTransaction = result.transaction
            hashes = result.hashes
            commitRedeemScript = result.redeemScript
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { manager, signatures in
                return manager.txBuilder.mapToRevealTransaction(
                    transaction: kaspaTransaction,
                    commitRedeemScript: commitRedeemScript.data,
                    signatures: signatures
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, tx in
                let encodedRawTransactionData = try? JSONEncoder().encode(tx)

                return manager
                    .networkService
                    .send(transaction: KaspaDTO.Send.Request(transaction: tx))
                    .handleEvents(receiveFailure: { [weak manager] _ in
                        // A failed reveal tx should trigger `wallet` update so the SDK consumer
                        // can observe and handle it (e.g. display a notification)
                        manager?.wallet.setAssetRequirements()
                    })
                    .wire { [weak manager] () -> AnyPublisher<Void, Error> in
                        guard let manager else {
                            return .anyFail(error: BlockchainSdkError.empty)
                        }

                        // Both failed and successful reveal txs should trigger the update of the UTXOs state in tx builder,
                        // therefore `wire` operator is used here
                        return manager.updateUnspentOutputs()
                    }
                    .mapAndEraseSendTxError(tx: encodedRawTransactionData?.hex())
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { manager, response in
                manager.handleSuccessfulRevealTokenTransaction(transaction, token: token, response: response)
            })
            .asyncMap { manager, response in
                // Delete Commit
                await manager.removeIncompleteTokenTransaction(for: token)
                return TransactionSendResult(hash: response.transactionId, currentProviderHost: manager.currentHost)
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let isTestnet = wallet.blockchain.isTestnet
        let source = wallet.address

        switch amount.type {
        case .token:
            return networkService
                .feeEstimate()
                .receive(on: DispatchQueue.global())
                .withWeakCaptureOf(self)
                .tryAsyncMap { manager, feeEstimate in
                    let transactionData = try await manager.txBuilder.buildForMassCalculationKRC20(
                        amount: amount,
                        feeRate: Int(feeEstimate.priorityBucket.feerate),
                        sourceAddress: source,
                        destination: destination
                    )
                    return (transactionData, feeEstimate: feeEstimate)
                }
                .withWeakCaptureOf(self)
                .flatMap { manager, args in
                    let (transactionData, feeEstimate) = args
                    return manager.networkService
                        .mass(data: transactionData)
                        .map { mass in
                            let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                            return feeMapper.mapTokenFee(mass: Decimal(mass.mass), feeEstimate: feeEstimate)
                        }
                }
                .eraseToAnyPublisher()
        case .coin:
            return networkService
                .feeEstimate()
                .receive(on: DispatchQueue.global())
                .withWeakCaptureOf(self)
                .tryAsyncMap { manager, feeEstimate in
                    let transactionData = try await manager.txBuilder.buildForMassCalculation(
                        amount: amount,
                        feeRate: Int(feeEstimate.priorityBucket.feerate),
                        sourceAddress: source,
                        destination: destination
                    )
                    return (transactionData, feeEstimate: feeEstimate)
                }
                .withWeakCaptureOf(self)
                .flatMap { manager, args in
                    let (transactionData, feeEstimate) = args
                    return manager.networkService
                        .mass(data: transactionData)
                        .map { mass in
                            let feeMapper = KaspaFeeMapper(isTestnet: manager.wallet.blockchain.isTestnet)
                            return feeMapper.mapFee(mass: mass, feeEstimate: feeEstimate)
                        }
                }
                .eraseToAnyPublisher()
        default:
            return .anyFail(error: BlockchainSdkError.notImplemented)
        }
    }

    private func updateWallet(_ response: UTXOResponse, tokensInfo: [Token: Result<KaspaBalanceResponseKRC20, Error>]) {
        unspentOutputManager.update(outputs: response.outputs, for: wallet.defaultAddress)
        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
        wallet.add(coinValue: balance)

        for (token, value) in tokensInfo {
            switch value {
            case .success(let tokenBalance):
                let decimalTokenBalance = (Decimal(stringValue: tokenBalance.result.first?.balance) ?? 0) / token.decimalValue
                wallet.add(tokenValue: decimalTokenBalance, for: token)
            case .failure:
                wallet.clearAmount(for: token)
            }
        }

        let pendingTransactions = response.pending.map {
            PendingTransactionRecordMapper().mapToPendingTransactionRecord(
                record: $0,
                blockchain: wallet.blockchain,
                address: wallet.address
            )
        }

        wallet.updatePendingTransaction(pendingTransactions)
    }

    /// A workaround for a badly designed Kaspa transaction builder, which has a stateful implementation
    /// instead of a stateless one, and therefore its unspent outputs must always be manually updated
    /// using this method before building a new Kaspa or KRC20 transaction.
    private func updateUnspentOutputs() -> AnyPublisher<Void, Error> {
        return networkService
            .getUnspentOutputs(address: wallet.address)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, unspentOutputs in
                walletManager.unspentOutputManager.update(outputs: unspentOutputs, for: walletManager.wallet.defaultAddress)
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    // MARK: - KRC20 Tokens management

    private func loadCachedIncompleteTokenTransactionsIfNeeded() -> some Publisher<Void, Error> {
        guard cardTokens != lastLoadedCardTokens else {
            // Incomplete transactions for the current set of tokens are already loaded from the cache
            return Just.justWithError(output: ())
        }

        return Just
            .justWithError(output: cardTokens)
            .withWeakCaptureOf(self)
            .asyncMap { manager, cardTokens in
                let dataStorage = manager.dataStorage
                let inMemoryStorage = manager.incompleteTokenTransactionsInMemoryStorage
                let walletAddress = manager.wallet.address

                let storedTransactionParams = await withTaskGroup(
                    of: (KaspaIncompleteTokenTransactionStorageID, KaspaKRC20.IncompleteTokenTransactionParams?).self,
                    returning: [KaspaIncompleteTokenTransactionStorageID: KaspaKRC20.IncompleteTokenTransactionParams].self
                ) { taskGroup in
                    for token in cardTokens {
                        taskGroup.addTask {
                            let storageId = token.asStorageId(walletAddress: walletAddress)
                            return (storageId, await dataStorage.get(key: storageId.id))
                        }
                    }

                    return await taskGroup.reduce(into: [:]) { partialResult, element in
                        let (storageId, transactionParams) = element
                        partialResult[storageId] = transactionParams
                    }
                }

                inMemoryStorage.mutate { storage in
                    storage.merge(storedTransactionParams, uniquingKeysWith: { old, _ in old })
                }

                return cardTokens
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { manager, loadedCardTokens in
                manager.lastLoadedCardTokens = loadedCardTokens
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func getIncompleteTokenTransaction(for asset: Asset) -> KaspaKRC20.IncompleteTokenTransactionParams? {
        switch asset {
        case .coin, .reserve, .feeResource:
            return nil
        case .token(let token):
            return incompleteTokenTransactionsInMemoryStorage[token.asStorageId(walletAddress: wallet.address)]
        }
    }

    private func store(incompleteTokenTransaction: KaspaKRC20.IncompleteTokenTransactionParams, for token: Token) async {
        let storageId = token.asStorageId(walletAddress: wallet.address)
        incompleteTokenTransactionsInMemoryStorage.mutate { $0[storageId] = incompleteTokenTransaction }
        await dataStorage.store(key: storageId.id, value: incompleteTokenTransaction)
    }

    private func removeIncompleteTokenTransaction(for token: Token) async {
        let storageId = token.asStorageId(walletAddress: wallet.address)
        incompleteTokenTransactionsInMemoryStorage.mutate { $0[storageId] = nil }
        await dataStorage.store(key: storageId.id, value: nil as KaspaKRC20.IncompleteTokenTransactionParams?)
    }

    private func makeTransaction(
        from incompleteTokenTransactionParams: KaspaKRC20.IncompleteTokenTransactionParams,
        for token: Token
    ) -> Transaction? {
        guard let tokenValue = Decimal(stringValue: incompleteTokenTransactionParams.envelope.amt) else {
            return nil
        }

        let blockchain = wallet.blockchain
        let transactionAmount = tokenValue / token.decimalValue
        let commitFeeAmount: Amount = .zeroCoin(for: blockchain) // The commit tx was already sent, therefore zero is used here
        let revealFee = Decimal(incompleteTokenTransactionParams.targetOutputAmount) / blockchain.decimalValue - dustValue.value
        let revealFeeAmount = Amount(with: blockchain, value: revealFee)

        return Transaction(
            amount: Amount(
                with: blockchain,
                type: .token(value: token),
                value: transactionAmount
            ),
            fee: Fee(
                commitFeeAmount + revealFeeAmount,
                parameters: KaspaKRC20.TokenTransactionFeeParams(
                    commitFee: commitFeeAmount,
                    revealFee: revealFeeAmount
                )
            ),
            sourceAddress: defaultSourceAddress,
            destinationAddress: incompleteTokenTransactionParams.envelope.to,
            changeAddress: defaultSourceAddress,
            params: incompleteTokenTransactionParams
        )
    }

    private func handleSuccessfulRevealTokenTransaction(
        _ transaction: Transaction,
        token: Token,
        response: KaspaDTO.Send.Response
    ) {
        let hash = response.transactionId
        let mapper = PendingTransactionRecordMapper()
        let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
        wallet.addPendingTransaction(record)
        pendingTokenTransactionHashes[token, default: []].insert(hash)
        wallet.clearAssetRequirements()
    }
}

// MARK: - DustRestrictable

extension KaspaWalletManager: DustRestrictable {
    var dustValue: Amount {
        let value = Decimal(KaspaTransactionBuilder.dustValue) / wallet.blockchain.decimalValue
        return Amount(with: wallet.blockchain, value: value)
    }

    func validateDust(amount: Amount, fee: Amount) throws {
        guard dustValue.type == amount.type else {
            return
        }

        // Max amount available to send
        let maxAmount: Amount? = switch amount.type {
        case .coin: txBuilder.availableAmount()
        default: wallet.amounts[amount.type]
        }

        guard let maxAmount else {
            throw ValidationError.balanceNotFound
        }

        if amount < dustValue {
            throw ValidationError.dustAmount(minimumAmount: dustValue)
        }

        // Total amount which will be spend
        var sendingAmount = amount.value

        if amount.type == fee.type {
            sendingAmount += fee.value
        }

        let change = maxAmount.value - sendingAmount
        if change > 0, change < dustValue.value {
            throw ValidationError.dustChange(minimumAmount: dustValue)
        }
    }
}

// MARK: - WithdrawalNotificationProvider

extension KaspaWalletManager: WithdrawalNotificationProvider {
    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        // The 'Mandatory amount change' withdrawal suggestion has been superseded by a validation performed in
        // the 'MaximumAmountRestrictable.validateMaximumAmount(amount:fee:)' method below
        return nil
    }
}

// MARK: - MaximumAmountRestrictable

extension KaspaWalletManager: MaximumAmountRestrictable {
    func validateMaximumAmount(amount: Amount, fee: Amount) throws {
        switch amount.type {
        case .token:
            let amountAvailableToSend = txBuilder.availableAmount()

            if fee <= amountAvailableToSend {
                return
            }

            throw ValidationError.maximumUTXO(
                blockchainName: wallet.blockchain.displayName,
                newAmount: amountAvailableToSend,
                maxUtxo: KaspaUnspentOutputManager.maxOutputsCount
            )

        default:
            let amountAvailableToSend = txBuilder.availableAmount() - fee

            if amount <= amountAvailableToSend {
                return
            }

            throw ValidationError.maximumUTXO(
                blockchainName: wallet.blockchain.displayName,
                newAmount: amountAvailableToSend,
                maxUtxo: KaspaUnspentOutputManager.maxOutputsCount
            )
        }
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension KaspaWalletManager: AssetRequirementsManager {
    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never> {
        let status: AssetRequirementFeeStatus = wallet.hasFeeCurrency(amountType: asset) ? .sufficient : .insufficient(missingAmount: "")
        return Just(status).eraseToAnyPublisher()
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        guard
            let token = asset.token,
            let incompleteTokenTransaction = getIncompleteTokenTransaction(for: asset)
        else {
            return nil
        }

        return .paidTransactionWithFee(
            blockchain: wallet.blockchain,
            transactionAmount: Amount(with: token, value: incompleteTokenTransaction.amount),
            feeAmount: nil
        )
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        return sendIncompleteKaspaTokenTransactionIfPossible(
            for: asset,
            signer: signer,
            validator: { _ in true }
        )
        .mapError { $0 }
        .mapToVoid()
        .eraseToAnyPublisher()
    }

    func discardRequirements(for asset: Asset) {
        guard let token = asset.token else {
            return
        }

        runTask(in: self) { walletManager in
            await walletManager.removeIncompleteTokenTransaction(for: token)
        }
    }
}

// MARK: - Convenience extensions

private extension Token {
    func asStorageId(walletAddress: String) -> KaspaIncompleteTokenTransactionStorageID {
        return KaspaIncompleteTokenTransactionStorageID(walletAddress: walletAddress, contractAddress: contractAddress)
    }
}
