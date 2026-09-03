//
//  TronWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class TronWalletManager: BaseWalletManager, WalletManager {
    var networkService: TronNetworkService!
    var txBuilder: TronTransactionBuilder!

    var currentHost: String {
        networkService.host
    }

    private let feeSigner = DummySigner()
    private let utils = TronUtils()

    func updateWalletManager(address: String) async throws {
        do {
            let accountInfo = try await networkService.accountInfo(
                for: address,
                tokens: cardTokens,
                transactionIDs: wallet.pendingTransactions.map { $0.hash }
            ).async()

            updateWallet(accountInfo)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return signedTransactionData(
            transaction: transaction,
            signer: signer,
            publicKey: wallet.publicKey
        )
        .withWeakCaptureOf(self)
        .flatMap { manager, data in
            manager.networkService
                .broadcastHex(data)
                .mapAndEraseSendTxError(tx: data.hex(), currentHost: manager.currentHost)
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, broadcastResponse -> TransactionSendResult in
            guard broadcastResponse.result == true else {
                throw BlockchainSdkError.failedToSendTx
            }

            let hash = broadcastResponse.txid
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
            manager.wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: hash, currentProviderHost: manager.currentHost)
        }
        .mapSendTxError(currentHost: currentHost)
        .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        feePublisher(amount: amount, destination: destination, callData: nil, memo: nil)
    }

    private func feePublisher(amount: Amount, destination: String, callData: Data?, memo: String?) -> AnyPublisher<[Fee], Error> {
        let hasMemo = memo?.isEmpty == false
        let energyFeePublisher = energyFeeParameters(amount: amount, destination: destination, callData: callData, hasMemo: hasMemo)

        let blockchain = wallet.blockchain

        let dummyTransactionType: TronTransactionParams.TransactionType = callData
            .map { .contractCall(callData: $0, feeLimit: nil) } ?? .transfer

        let dummyTransaction = Transaction(
            amount: amount,
            fee: Fee(.zeroCoin(for: blockchain)),
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address,
            params: TronTransactionParams(transactionType: dummyTransactionType, memo: memo)
        )

        let transactionDataPublisher = signedTransactionData(
            transaction: dummyTransaction,
            signer: feeSigner,
            publicKey: feeSigner.publicKey
        )

        return Publishers.Zip4(
            energyFeePublisher,
            networkService.accountExists(address: destination),
            transactionDataPublisher,
            networkService.getAccountResource(for: wallet.address)
        )
        .map {
            energyFeeParameters,
                destinationExists,
                transactionData,
                resources -> [Fee] in
            let memoFee = hasMemo ? Decimal(energyFeeParameters.memoFee) : .zero

            if !destinationExists, amount.type == .coin, callData == nil {
                let amount = Amount(with: blockchain, value: Constants.accountActivationFee + memoFee / blockchain.decimalValue)
                return [Fee(amount)]
            }

            let sunPerBandwidthPoint = 1000

            let remainingBandwidth = resources.freeNetLimit - (resources.freeNetUsed ?? 0)
            let additionalDataSize = 64
            let transactionSizeFee = transactionData.count + additionalDataSize
            let consumedBandwidthFee: Int
            if transactionSizeFee <= remainingBandwidth {
                consumedBandwidthFee = 0
            } else {
                consumedBandwidthFee = transactionSizeFee * sunPerBandwidthPoint
            }

            let remainingEnergy = (resources.energyLimit ?? .zero) - (resources.energyUsed ?? .zero)
            let consumedEnergyFee = max(
                .zero,
                Decimal(energyFeeParameters.energyFee) - remainingEnergy
            ) * Decimal(energyFeeParameters.sunPerEnergyUnit)

            let totalFee = Decimal(consumedBandwidthFee) + consumedEnergyFee + memoFee

            let value = totalFee / blockchain.decimalValue
            let amount = Amount(with: blockchain, value: value)

            let feeParameters = TronFeeParameters(
                energySpent: min(
                    energyFeeParameters.energyFee,
                    remainingEnergy.decimalNumber.intValue
                ),
                energyFullyCoversFee: consumedEnergyFee == .zero
            )

            return [Fee(amount, parameters: feeParameters)]
        }
        .eraseToAnyPublisher()
    }

    private func energyFeeParameters(amount: Amount, destination: String, callData: Data?, hasMemo: Bool) -> AnyPublisher<TronEnergyFeeData, Error> {
        if let callData {
            return contractCallEnergyFeeParameters(destination: destination, callData: callData, callValue: amount)
        }

        guard let contractAddress = amount.type.token?.contractAddress else {
            // A plain coin transfer consumes no energy, but a memo still costs its flat fee.
            if hasMemo {
                return networkService.chainParameters()
                    .map { TronEnergyFeeData(energyFee: 0, sunPerEnergyUnit: 0, memoFee: $0.memoFee) }
                    .eraseToAnyPublisher()
            }

            return .justWithError(output: TronEnergyFeeData(energyFee: 0, sunPerEnergyUnit: 0, memoFee: 0))
        }

        let energyUsagePublisher = Result {
            try txBuilder.buildContractEnergyUsageData(amount: amount, destinationAddress: destination)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { manager, energyUsageData in
            manager.networkService.contractEnergyUsage(
                sourceAddress: manager.wallet.address,
                contractAddress: contractAddress,
                contractEnergyUsageData: energyUsageData
            )
        }

        let skipDynamicIncrease = amount.type.token?.contractAddress == Constants.usdtContractAddress

        return energyUsagePublisher.zip(networkService.chainParameters())
            .map { energyUse, chainParameters in
                Self.conservativeEnergyFeeData(energyUse: energyUse, chainParameters: chainParameters, skipDynamicIncrease: skipDynamicIncrease)
            }
            .eraseToAnyPublisher()
    }

    private func contractCallEnergyFeeParameters(destination: String, callData: Data, callValue: Amount) -> AnyPublisher<TronEnergyFeeData, Error> {
        let callValueSun = UInt64(clamping: utils.convertAmountToMinimalUnits(callValue))

        let energyUsagePublisher = networkService.contractEnergyUsage(
            sourceAddress: wallet.address,
            contractAddress: destination,
            callDataHex: callData.hex(),
            callValue: callValueSun
        )

        let skipDynamicIncrease = destination == Constants.usdtContractAddress

        return energyUsagePublisher.zip(networkService.chainParameters())
            .map { energyUse, chainParameters in
                Self.conservativeEnergyFeeData(energyUse: energyUse, chainParameters: chainParameters, skipDynamicIncrease: skipDynamicIncrease)
            }
            .eraseToAnyPublisher()
    }

    /// A contract's dynamic energy factor can rise every maintenance period (6 hours), and we don't know
    /// which period the transaction will execute in — so the estimate is padded by the chain's dynamic-energy
    /// increase factor (currently 20%). Skipped for USDT, whose factor is already pegged at the chain
    /// maximum and can't rise further.
    private static func conservativeEnergyFeeData(energyUse: Int, chainParameters: TronChainParameters, skipDynamicIncrease: Bool) -> TronEnergyFeeData {
        let dynamicEnergyIncreaseFactorPrecision = 10_000
        let dynamicEnergyIncreaseFactor: Double = skipDynamicIncrease
            ? .zero
            : Double(chainParameters.dynamicEnergyIncreaseFactor) / Double(dynamicEnergyIncreaseFactorPrecision)

        let conservativeEnergyFee = Int(Double(energyUse) * (1 + dynamicEnergyIncreaseFactor))

        return TronEnergyFeeData(
            energyFee: conservativeEnergyFee,
            sunPerEnergyUnit: chainParameters.sunPerEnergyUnit,
            memoFee: chainParameters.memoFee
        )
    }

    private func signedTransactionData(transaction: Transaction, signer: TransactionSigner, publicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        networkService.getNowBlock()
            .withWeakCaptureOf(self)
            .tryMap { manager, block in
                try manager.txBuilder.buildForSign(transaction: transaction, block: block)
            }
            .flatMap { presignedInput in
                signer.sign(hash: presignedInput.hash, walletPublicKey: publicKey)
                    .withWeakCaptureOf(self)
                    .tryMap { manager, signature in
                        let unmarshalledSignature = manager.unmarshal(signature, hash: presignedInput.hash, publicKey: publicKey)
                        return try manager.txBuilder.buildForSend(rawData: presignedInput.rawData, signature: unmarshalledSignature)
                    }
            }
            .eraseToAnyPublisher()
    }

    private func updateWallet(_ accountInfo: TronAccountInfo) {
        wallet.add(amount: Amount(with: wallet.blockchain, value: accountInfo.balance))

        for (token, balance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }

        wallet.removePendingTransaction { hash in
            accountInfo.confirmedTransactionIDs.contains(hash)
        }
    }

    private func unmarshal(_ signatureData: Data, hash: Data, publicKey: Wallet.PublicKey) -> Data {
        guard publicKey != feeSigner.publicKey else {
            return signatureData + Data(0)
        }

        do {
            let signature = try Secp256k1Signature(with: signatureData)
            let unmarshalledSignature = try signature.unmarshal(with: publicKey.blockchainKey, hash: hash).data

            return unmarshalledSignature
        } catch {
            BSDKLogger.error(error: error)
            return Data()
        }
    }
}

extension TronWalletManager: ThenProcessable {}

// MARK: - TronGaslessTransactionsBuilder

extension TronWalletManager: TronGaslessTransactionsBuilder {
    func buildForGaslessSubmit(
        originalTransaction: Transaction,
        compensationTransaction: Transaction,
        signer: TransactionSigner
    ) async throws -> TronGaslessSignedTransactions {
        let block = try await networkService.getNowBlock().async()
        let compensationPresignedInput = try txBuilder.buildForSign(transaction: compensationTransaction, block: block)
        let originalPresignedInput = try txBuilder.buildForSign(transaction: originalTransaction, block: block)
        let signatures = try await signer.sign(
            hashes: [compensationPresignedInput.hash, originalPresignedInput.hash],
            walletPublicKey: wallet.publicKey
        ).async()

        guard signatures.count == 2,
              let compensationSignatureInfo = signatures.first(where: { $0.hash == compensationPresignedInput.hash }),
              let originalSignatureInfo = signatures.first(where: { $0.hash == originalPresignedInput.hash }) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let encoder = TronTransactionJSONEncoder()
        let compensationSignature = unmarshal(
            compensationSignatureInfo.signature,
            hash: compensationPresignedInput.hash,
            publicKey: wallet.publicKey
        )
        let originalSignature = unmarshal(
            originalSignatureInfo.signature,
            hash: originalPresignedInput.hash,
            publicKey: wallet.publicKey
        )

        return TronGaslessSignedTransactions(
            signedCompensationTx: try encoder.encode(
                rawData: compensationPresignedInput.rawData,
                signature: compensationSignature
            ),
            signedOriginalTx: try encoder.encode(
                rawData: originalPresignedInput.rawData,
                signature: originalSignature
            )
        )
    }
}

private class DummySigner: TransactionSigner {
    let privateKey: Data
    let publicKey: Wallet.PublicKey

    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        publicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivationType: .none)
        privateKey = keyPair.privateKey
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        do {
            let signature = try Secp256k1Utils().sign(hash, with: privateKey)
            return Just(.init(signature: signature, publicKey: walletPublicKey.blockchainKey, hash: hash))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        fatalError()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        fatalError()
    }
}

// MARK: - TronAllowanceProvider

extension TronWalletManager: TronAllowanceProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, any Error> {
        let allowanceDataPublisher = Result {
            try txBuilder.buildForAllowance(owner: owner, spender: spender)
        }.publisher

        return allowanceDataPublisher
            .withWeakCaptureOf(self)
            .flatMap { manager, allowanceData in
                manager.networkService.getAllowance(owner: owner, contractAddress: contractAddress, allowanceData: allowanceData)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TronTransactionFeeProvider

extension TronWalletManager: TronTransactionFeeProvider {
    func getFee(amount: Amount, destination: String, callData: Data?, memo: String?) async throws -> [Fee] {
        try await feePublisher(amount: amount, destination: destination, callData: callData, memo: memo).async()
    }
}

// MARK: - TronTransactionDataBuilder

extension TronWalletManager: TronTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Amount) throws -> Data {
        return try txBuilder.buildForApprove(spender: spender, amount: amount)
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension TronWalletManager: StakeKitTransactionSender, StakingTransactionsBuilder, StakeKitTransactionDataProvider {
    typealias RawTransaction = Data

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try TronStakeKitTransactionHelper().prepareForSign(transaction.unsignedData).hash
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        let rawData = try TronStakeKitTransactionHelper().prepareForSign(transaction.unsignedData).rawData
        let unmarshalled = unmarshal(signature.signature, hash: signature.hash, publicKey: wallet.publicKey)
        return try txBuilder.buildForSend(rawData: rawData, signature: unmarshalled)
    }
}

extension TronWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(rawTransaction: RawTransaction) async throws -> String {
        try await networkService.broadcastHex(rawTransaction).async().txid
    }
}

// MARK: - PendingTransactionRecordAdding

extension TronWalletManager: PendingTransactionRecordAdding {
    public func addPendingTransaction(_ transaction: Transaction, hash: String) {
        let mapper = PendingTransactionRecordMapper()
        wallet.addPendingTransaction(mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash))
    }
}

private extension TronWalletManager {
    enum Constants {
        static let usdtContractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        static let accountActivationFee: Decimal = 1.1
    }
}

// MARK: - WithdrawalNotificationProvider

extension TronWalletManager: WithdrawalNotificationProvider {
    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        guard amount.type.isToken, !fee.amount.type.isToken else {
            return nil
        }

        return .tronWillBeSendTokenFeeDescription
    }
}
