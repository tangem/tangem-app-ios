//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import TangemFoundation

class BitcoinWalletManager: BaseWalletManager, WalletManager, DustRestrictable, MultiAddressesWalletManagerUpdater {
    let txBuilder: BitcoinTransactionBuilder
    let unspentOutputManager: UnspentOutputManager
    let networkService: UTXONetworkProvider

    /*
     The current default minimum relay fee is 1 sat/vbyte.
     https://learnmeabitcoin.com/technical/transaction/fee/#:~:text=The%20current%20default%20minimum%20relay,mined%20in%20to%20the%20blockchain.
     */
    var minimalFeePerByte: Decimal { 1 }
    var minimalFee: Decimal { 0.00001 }
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }

    var currentHost: String { networkService.host }

    init(
        wallet: Wallet,
        txBuilder: BitcoinTransactionBuilder,
        unspentOutputManager: UnspentOutputManager,
        networkService: UTXONetworkProvider
    ) {
        self.txBuilder = txBuilder
        self.unspentOutputManager = unspentOutputManager
        self.networkService = networkService

        super.init(wallet: wallet)
    }

    func updateWalletManager(addresses: [any Address]) async throws {
        do {
            let responses = try await networkService.getInfo(addresses: addresses).async()
            updateWallet(with: responses)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func updateWallet(with responses: [UTXONetworkProviderUpdatingResponse]) {
        unspentOutputManager.clearOutputs()

        responses.forEach { response in
            unspentOutputManager.update(outputs: response.response.outputs, for: response.address)
        }
        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
        wallet.add(coinValue: balance)

        let mapper = PendingTransactionRecordMapper()
        let pending = responses.flatMap { response in
            response.response.pending.map {
                mapper.mapToPendingTransactionRecord(record: $0, blockchain: wallet.blockchain, address: response.address.value)
            }
        }

        wallet.updatePendingTransaction(pending)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService.getFee()
            .withWeakCaptureOf(self)
            .asyncTryMap { try await $0.processFee($1, amount: amount, destination: destination) }
            .eraseToAnyPublisher()
    }

    func processFee(_ response: UTXOFee, amount: Amount, destination: String) async throws -> [Fee] {
        typealias FeeWithFeeRate = (fee: Int, rate: Int)

        let changeAddress = wallet.changeAddress.value

        async let minFee: FeeWithFeeRate = {
            let rate = max(response.slowSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate, changeAddress: changeAddress)
            return (fee: fee, rate: rate)
        }()

        async let normalFee: FeeWithFeeRate = {
            let rate = max(response.marketSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate, changeAddress: changeAddress)
            return (fee: fee, rate: rate)
        }()

        async let maxFee: FeeWithFeeRate = {
            let rate = max(response.prioritySatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate, changeAddress: changeAddress)
            return (fee: fee, rate: rate)
        }()

        let decimalValue = wallet.blockchain.decimalValue

        return try await [
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(minFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: minFee.rate)
            ),
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(normalFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: normalFee.rate)
            ),
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(maxFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: maxFee.rate)
            ),
        ]
    }
}

// MARK: - MultipleXPUBWalletManagerUpdater

extension BitcoinWalletManager: XPUBWalletManagerUpdater, MultipleXPUBWalletManagerUpdater {
    func updateWalletManager(xpubs: [UTXOXpubScriptType]) async throws {
        do {
            let responses = try await networkService.getInfo(xpubs: xpubs).async()
            try updateWallet(with: responses)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    private func updateWallet(with responses: [UTXOXpubNetworkProviderUpdatingResponse]) throws {
        let usedAddresses = responses
            .flatMap(\.info.addresses)
            .map(\.usedAddress)

        wallet.update(usedAddresses: usedAddresses)

        unspentOutputManager.clearOutputs()
        try responses.flatMap(\.outputs).forEach { address, outputs in
            if let address = wallet.addresses.first(where: { $0.value == address.address }) {
                unspentOutputManager.update(outputs: outputs, for: address)
            } else {
                BSDKLogger.error(error: "Don't expect to be called. Address not found in wallet")
                try unspentOutputManager.update(outputs: outputs, for: address.address)
            }
        }

        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
        wallet.add(coinValue: balance)

        let mapper = PendingTransactionRecordMapper()
        let pending = responses.flatMap(\.pending).map { record in
            mapper.mapToPendingTransactionRecord(
                record: record,
                blockchain: wallet.blockchain,
                address: wallet.address
            )
        }

        wallet.updatePendingTransaction(pending)
    }
}

// MARK: - BitcoinTransactionFeeCalculator

extension BitcoinWalletManager: BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Amount, destination: String) async throws -> Fee {
        let decimalValue = wallet.blockchain.decimalValue
        let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: satoshiPerByte, changeAddress: wallet.changeAddress.value)
        let amount = Amount(with: wallet.blockchain, value: Decimal(fee) / decimalValue)

        return Fee(amount, parameters: BitcoinFeeParameters(rate: satoshiPerByte))
    }
}

// MARK: - TransactionSender

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Future.async {
            try await self.txBuilder.buildForSign(transaction: transaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, preImageHashes in
            let dataToSign = manager.mapToSignData(preImageHashes: preImageHashes)
            return signer
                .sign(dataToSign: dataToSign, walletPublicKey: manager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .asyncTryMap { manager, signatures -> String in
            let tx = try await manager.txBuilder.buildForSend(transaction: transaction, signatures: signatures)
            return tx.hex()
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, transaction in
            manager.networkService
                .send(transaction: transaction)
                .mapAndEraseSendTxError(tx: transaction, currentHost: manager.currentHost)
        }
        .withWeakCaptureOf(self)
        .map { manager, result in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: result.hash)
            manager.wallet.addPendingTransaction(record)
            return result
        }
        .mapSendTxError(currentHost: currentHost)
        .eraseToAnyPublisher()
    }
}

// MARK: - XPUBAddressesWalletManagerProvider

extension BitcoinWalletManager: XPUBAddressesWalletManagerProvider {
    var hasPendingUnspentOutputs: Bool {
        !unspentOutputManager.pendingOutputs().isEmpty
    }

    func compoundTransactionIfNeeded() -> (amount: Amount, destination: String)? {
        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
        guard balance > 0 else {
            return nil
        }

        guard let plainWallet = try? makePlainWallet() else {
            return nil
        }

        let plainWalletScripts = plainWallet.addresses
            .compactMap { ($0 as? LockingScriptAddress)?.lockingScript }
            .toSet()

        let outputScripts = unspentOutputManager.availableOutputs()
            .map(\.script)
            .toSet()

        let outputsOutsidePlainWallet = outputScripts.subtracting(plainWalletScripts)

        guard !outputsOutsidePlainWallet.isEmpty else {
            return nil
        }

        let amount = Amount(with: wallet.blockchain, value: balance)
        return (amount: amount, destination: plainWallet.address)
    }

    func updateToXpubKey(xpubKey: Wallet.PublicKey.XPUBKey) throws {
        wallet = try makeXpubWallet(xpubKey: xpubKey)
        setNeedsUpdate()
    }

    func updateToPlainKey() throws {
        wallet = try makePlainWallet()
        setNeedsUpdate()
    }

    private func makeXpubWallet(xpubKey: Wallet.PublicKey.XPUBKey) throws -> Wallet {
        guard case .plain(let plainKey) = wallet.publicKey.derivationType else {
            throw XPUBAddressesWalletManagerProviderError.plainHDKeyNotFound
        }

        return try makeWallet(derivationType: .xpub(plain: plainKey, xpub: xpubKey))
    }

    private func makePlainWallet() throws -> Wallet {
        guard case .xpub(let plainKey, _) = wallet.publicKey.derivationType else {
            throw XPUBAddressesWalletManagerProviderError.xpubHDKeyNotFound
        }

        return try makeWallet(derivationType: .plain(plainKey))
    }

    private func makeWallet(derivationType: Wallet.PublicKey.DerivationType) throws -> Wallet {
        let publicKey = Wallet.PublicKey(
            seedKey: wallet.publicKey.seedKey,
            derivationType: derivationType
        )
        let factory = WalletFactory(blockchain: wallet.blockchain)
        return try factory.makeWallet(publicKey: publicKey)
    }
}

// MARK: - XPUBAddressesBalancesChecker

extension BitcoinWalletManager: XPUBAddressesBalancesChecker {
    func checkOtherAddressesBalances(xpubKey: Wallet.PublicKey.XPUBKey) async throws -> XPUBAddressesBalancesReport {
        let xpub = try XPUBUtils.generateXPUB(key: xpubKey, isTestnet: wallet.blockchain.isTestnet)
        let scriptTypes = try XPUBUtils.scriptTypes(blockchain: wallet.blockchain, xpub: xpub)
        let info = try await networkService.getInfo(xpubs: scriptTypes).async()

        let walletAddresses = wallet.addresses.uniqueProperties(\.value).toSet()

        let otherAddressesBalances: [String: Decimal] = info.flatMap(\.info.addresses)
            .filter { !walletAddresses.contains($0.usedAddress.address) && $0.balance > 0 }
            .reduce(into: [:]) { $0[$1.usedAddress.address] = $1.balance }

        return XPUBAddressesBalancesReport(otherAddressesBalances: otherAddressesBalances)
    }
}

// MARK: - Private

private extension BitcoinWalletManager {
    func mapToSignData(preImageHashes: [UTXOTransactionSerializerPreImageHash]) -> [SignData] {
        let grouped = Dictionary(grouping: preImageHashes) { preImageHash -> DerivationPublicKey in
            switch preImageHash.spendableType {
            case .publicKey(let key):
                return key
            case .redeemScript:
                return DerivationPublicKey(
                    publicKey: wallet.publicKey.blockchainKey,
                    derivationPath: wallet.publicKey.derivationPath
                )
            }
        }

        return grouped.map { key, hashes in
            SignData(
                derivationPath: key.derivationPath,
                hashes: hashes.map(\.hashToSign),
                publicKey: key.publicKey
            )
        }
    }
}
