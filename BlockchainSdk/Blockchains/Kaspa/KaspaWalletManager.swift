//
//  KaspaWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaWalletManager: BaseManager, WalletManager {
    var txBuilder: KaspaTransactionBuilder!
    var networkService: KaspaNetworkService!
    var networkServiceKRC20: KaspaNetworkServiceKRC20!
    var dataStorage: BlockchainDataStorage!

    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let unconfirmedTransactionHashes = wallet.pendingTransactions.map { $0.hash }

        cancellable = Publishers.Zip(
            networkService.getInfo(address: wallet.address, unconfirmedTransactionHashes: unconfirmedTransactionHashes),
            networkServiceKRC20.balance(address: wallet.address, tokens: cardTokens)
        )
        .sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                self.wallet.clearAmounts()
                completion(.failure(error))
            case .finished:
                completion(.success(()))
            }
        }, receiveValue: { [weak self] kaspaAddressInfo, kaspaTokensInfo in
            self?.updateWallet(kaspaAddressInfo, tokensInfo: kaspaTokensInfo)
            completion(.success(()))
        })
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        switch transaction.amount.type {
        case .token(value: let token):

            switch transaction.params {
            case is KaspaKRC20.IncompleteTokenTransactionParams:
                return sendKaspaRevealTokenTransaction(transaction, token: token, signer: signer)
            default:
                return sendKaspaTokenTransaction(transaction, token: token, signer: signer)
            }

        default:
            return sendKaspaCoinTransaction(transaction, signer: signer)
        }
    }

    private func sendKaspaCoinTransaction(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let kaspaTransaction: KaspaTransaction
        let hashes: [Data]

        do {
            let result = try txBuilder.buildForSign(transaction)
            kaspaTransaction = result.0
            hashes = result.1
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }

                return txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)
            }
            .flatMap { [weak self] tx -> AnyPublisher<KaspaTransactionResponse, Error> in
                guard let self = self else { return .emptyFail }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)

                return networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: $0.transactionId)
                self?.wallet.addPendingTransaction(record)
            })
            .map {
                TransactionSendResult(hash: $0.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    private func sendKaspaTokenTransaction(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let txgroup: KaspaKRC20.TransactionGroup
        let meta: KaspaKRC20.TransactionMeta
        var builtKaspaRevealTx: KaspaTransactionData?

        do {
            let result = try txBuilder.buildForSendKRC20(transaction: transaction, token: token)
            txgroup = result.0
            meta = result.1
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: txgroup.hashesCommit + txgroup.hashesReveal, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }
                // Build Commit & Reveal
                let commitSignatures = Array(signatures[..<txgroup.hashesCommit.count])
                let revealSignatures = Array(signatures[txgroup.hashesCommit.count...])

                let commitTx = txBuilder.buildForSend(
                    transaction: txgroup.kaspaCommitTransaction,
                    signatures: commitSignatures
                )
                let revealTx = txBuilder.buildForSendReveal(
                    transaction: txgroup.kaspaRevealTransaction,
                    commitRedeemScript: meta.redeemScriptCommit,
                    signatures: revealSignatures
                )

                builtKaspaRevealTx = revealTx

                return (commitTx, revealTx)
            }
            .withWeakCaptureOf(self)
            .flatMap { (manager, txs: (tx: KaspaTransactionData, tx2: KaspaTransactionData)) -> AnyPublisher<KaspaTransactionResponse, Error> in
                // Send Commit
                let encodedRawTransactionData = try? JSONEncoder().encode(txs.tx)

                return manager.networkService
                    .send(transaction: KaspaTransactionRequest(transaction: txs.tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .asyncMap { manager, response in
                // Store Commit
                await manager.store(incompleteTokenTransaction: meta.incompleteTransactionParams, for: token)
                return response
            }
            .eraseToAnyPublisher()
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .flatMap { manager, response -> AnyPublisher<KaspaTransactionResponse, Error> in
                // Send Reveal
                guard let tx = builtKaspaRevealTx else {
                    return .anyFail(error: WalletError.failedToBuildTx)
                }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)
                return manager.networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: $0.transactionId)
                self?.wallet.addPendingTransaction(record)
            })
            .withWeakCaptureOf(self)
            .asyncMap { manager, response in
                // Delete Commit
                await manager.remove(incompleteTokenTransactionID: meta.incompleteTransactionParams.transactionId, for: token)
                return TransactionSendResult(hash: response.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    private func sendKaspaRevealTokenTransaction(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let kaspaTransaction: KaspaTransaction
        let commitRedeemScript: KaspaKRC20.RedeemScript
        let hashes: [Data]

        guard let params = transaction.params as? KaspaKRC20.IncompleteTokenTransactionParams,
              // Here, we use fee, which is obtained from previously saved data and the hardcoded dust value
              let feeParams = transaction.fee.parameters as? KaspaKRC20.RevealTransactionFeeParameter
        else {
            return .sendTxFail(error: WalletError.failedToBuildTx)
        }

        do {
            let result = try txBuilder.buildRevealTransaction(
                sourceAddress: transaction.sourceAddress,
                params: params,
                fee: .init(feeParams.amount)
            )

            kaspaTransaction = result.transaction
            hashes = result.hashes
            commitRedeemScript = result.redeemScript
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }

                return txBuilder.buildForSendReveal(transaction: kaspaTransaction, commitRedeemScript: commitRedeemScript, signatures: signatures)
            }
            .flatMap { [weak self] tx -> AnyPublisher<KaspaTransactionResponse, Error> in
                guard let self = self else { return .emptyFail }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)

                return networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: $0.transactionId)
                self?.wallet.addPendingTransaction(record)
            })
            .withWeakCaptureOf(self)
            .asyncMap { manager, input in
                await manager.remove(incompleteTokenTransactionID: params.transactionId, for: token)
                return TransactionSendResult(hash: input.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let blockchain = wallet.blockchain
        let isTestnet = blockchain.isTestnet
        let source = wallet.address

        let transaction = Transaction(
            amount: amount,
            fee: Fee(Amount.zeroCoin(for: blockchain)),
            sourceAddress: source,
            destinationAddress: destination,
            changeAddress: source
        )

        switch amount.type {
        case .token(let token):
            return Result {
                try txBuilder.buildForMassCalculationKRC20(transaction: transaction, token: token)
            }
            .publisher
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, transactionData in
                networkService.mass(data: transactionData)
                    .zip(networkService.feeEstimate())
            }
            .map { mass, feeEstimate in
                let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                return feeMapper.mapTokenFee(mass: Decimal(mass.mass), feeEstimate: feeEstimate)
            }
            .eraseToAnyPublisher()

        default:
            return Result {
                try txBuilder.buildForMassCalculation(transaction: transaction)
            }
            .publisher
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, transactionData in
                networkService.mass(data: transactionData)
                    .zip(networkService.feeEstimate())
            }
            .map { mass, feeEstimate in
                let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                return feeMapper.mapFee(mass: mass, feeEstimate: feeEstimate)
            }
            .eraseToAnyPublisher()
        }
    }

    private func updateWallet(_ info: KaspaAddressInfo, tokensInfo: [Token: Result<KaspaBalanceResponseKRC20, Error>]) {
        wallet.add(amount: Amount(with: wallet.blockchain, value: info.balance))
        txBuilder.setUnspentOutputs(info.unspentOutputs)

        for token in tokensInfo {
            switch token.value {
            case .success(let tokenBalance):
                let decimalTokenBalance = (Decimal(stringValue: tokenBalance.result.first?.balance) ?? 0) / token.key.decimalValue
                wallet.add(tokenValue: decimalTokenBalance, for: token.key)
            case .failure:
                wallet.clearAmount(for: token.key)
            }
        }

        wallet.removePendingTransaction { hash in
            info.confirmedTransactionHashes.contains(hash)
        }
    }
}

extension KaspaWalletManager: ThenProcessable {}

extension KaspaWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: Decimal(0.2))
    }
}

extension KaspaWalletManager: WithdrawalNotificationProvider {
    // Chia, kaspa have the same logic
    @available(*, deprecated, message: "Use MaximumAmountRestrictable")
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning? {
        let amountAvailableToSend = txBuilder.availableAmount() - fee
        if amount <= amountAvailableToSend {
            return nil
        }

        let amountToReduceBy = amount - amountAvailableToSend

        return WithdrawalWarning(
            warningMessage: Localization.commonUtxoValidateWithdrawalMessageWarning(
                wallet.blockchain.displayName,
                txBuilder.maxInputCount,
                amountAvailableToSend.description
            ),
            reduceMessage: Localization.commonOk,
            suggestedReduceAmount: amountToReduceBy
        )
    }

    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        // The 'Mandatory amount change' withdrawal suggestion has been superseded by a validation performed in
        // the 'MaximumAmountRestrictable.validateMaximumAmount(amount:fee:)' method below
        return nil
    }
}

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
                maxUtxo: txBuilder.maxInputCount
            )

        default:
            let amountAvailableToSend = txBuilder.availableAmount() - fee

            if amount <= amountAvailableToSend {
                return
            }

            throw ValidationError.maximumUTXO(
                blockchainName: wallet.blockchain.displayName,
                newAmount: amountAvailableToSend,
                maxUtxo: txBuilder.maxInputCount
            )
        }
    }
}

public protocol KaspaIncompleteTransactionUtilProtocol {
    func getIncompleteTokenTransaction(for token: Token) async -> Transaction?
    func getFeeIncompleteTokenTransaction() -> AnyPublisher<[Fee], Error>
}

extension KaspaWalletManager: KaspaIncompleteTransactionUtilProtocol {
    func getFeeIncompleteTokenTransaction() -> AnyPublisher<[Fee], Error> {
        let blockchain = wallet.blockchain
        let isTestnet = blockchain.isTestnet

        return networkService.feeEstimate()
            .map { feeEstimate in
                let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                return feeMapper.mapTokenFee(mass: KaspaKRC20.RevealTransactionMassConstant, feeEstimate: feeEstimate)
            }
            .eraseToAnyPublisher()
    }

    func getIncompleteTokenTransaction(for token: Token) async -> Transaction? {
        let key = KaspaIncompleteTokenTransactionStorageID(
            walletAddress: wallet.address,
            contractAddress: token.contractAddress
        ).id
        guard let tx: KaspaKRC20.IncompleteTokenTransactionParams = await dataStorage.get(key: key) else {
            return nil
        }

        return transaction(from: tx, for: token)
    }

    func store(incompleteTokenTransaction: KaspaKRC20.IncompleteTokenTransactionParams, for token: Token) async {
        let key = KaspaIncompleteTokenTransactionStorageID(
            walletAddress: wallet.address,
            contractAddress: token.contractAddress
        ).id
        let data = incompleteTokenTransaction

        await dataStorage.store(key: key, value: data)
    }

    func remove(incompleteTokenTransactionID: String, for token: Token) async {
        let key = KaspaIncompleteTokenTransactionStorageID(
            walletAddress: wallet.address,
            contractAddress: token.contractAddress
        ).id
        await dataStorage.store(key: key, value: nil as KaspaKRC20.IncompleteTokenTransactionParams?)
    }

    func transaction(from incompleteTokenTransationID: String, for token: Token) async -> Transaction? {
        let key = KaspaIncompleteTokenTransactionStorageID(
            walletAddress: wallet.address,
            contractAddress: token.contractAddress
        ).id
        let dict: [String: KaspaKRC20.IncompleteTokenTransactionParams] = await dataStorage.get(key: key) ?? [:]

        guard let params = dict[incompleteTokenTransationID] else {
            return nil
        }

        return transaction(from: params, for: token)
    }

    func transaction(from incompleteTokenTransationParams: KaspaKRC20.IncompleteTokenTransactionParams, for token: Token) -> Transaction? {
        guard let tokenValue = Decimal(stringValue: incompleteTokenTransationParams.envelope.amt) else {
            return nil
        }

        let transactionAmount = tokenValue / token.decimalValue
        let fee = Decimal(incompleteTokenTransationParams.amount / wallet.blockchain.decimalValue.uint64Value) - dustValue.value
        let feeAmount = Amount(with: wallet.blockchain, value: fee)

        return Transaction(
            amount: .init(
                with: wallet.blockchain,
                type: .token(value: token),
                value: transactionAmount
            ),
            fee: .init(feeAmount, parameters: KaspaKRC20.RevealTransactionFeeParameter(amount: feeAmount)),
            sourceAddress: defaultSourceAddress,
            destinationAddress: incompleteTokenTransationParams.envelope.to,
            changeAddress: defaultSourceAddress,
            params: incompleteTokenTransationParams
        )
    }
}
