//
//  KoinosWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk

class KoinosWalletManager: BaseManager, WalletManager, FeeResourceRestrictable {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    var feeResourceType: FeeResourceType {
        .mana
    }

    private let networkService: KoinosNetworkService
    private let transactionBuilder: KoinosTransactionBuilder

    private var koinContractId: String?

    init(
        wallet: Wallet,
        networkService: KoinosNetworkService,
        transactionBuilder: KoinosTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    override func updateWalletManager() async throws {
        do {
            // Build existingTransactionIDs equivalent
            async let existingTransactionIDs: Set<String> = {
                guard !wallet.pendingTransactions.isEmpty else {
                    return []
                }

                return try await networkService
                    .getExistingTransactionIDs(transactionIDs: wallet.pendingTransactions.map(\.hash))
                    .async()
            }()

            // Fetch account info
            async let accountInfo = networkService
                .getInfo(address: wallet.address, koinContractId: koinContractId)
                .async()

            // Update state
            try await update(accountInfo: accountInfo, existingTransactionIDs: existingTransactionIDs)

        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    private func update(accountInfo: KoinosAccountInfo, existingTransactionIDs: Set<String>) {
        koinContractId = accountInfo.koinContractId
        let atomicUnitMultiplier = wallet.blockchain.decimalValue
        let koinBalance = Decimal(accountInfo.koinBalance) / atomicUnitMultiplier
        let mana = Decimal(accountInfo.mana) / atomicUnitMultiplier

        wallet.add(
            amount: Amount(
                with: wallet.blockchain,
                type: .coin,
                value: koinBalance
            )
        )
        wallet.add(
            amount: Amount(
                with: wallet.blockchain,
                type: .feeResource(.mana),
                value: mana
            )
        )

        wallet.removePendingTransaction(where: existingTransactionIDs.contains)
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let manaLimit = transaction.fee.amount.value
        let transactionDataWithMana = transaction.then {
            $0.params = KoinosTransactionParams(manaLimit: manaLimit)
        }

        return networkService.getCurrentNonce(address: wallet.address)
            .tryMap { [transactionBuilder, koinContractId] nonce in
                try transactionBuilder.buildForSign(
                    transaction: transactionDataWithMana,
                    currentNonce: nonce,
                    koinContractId: koinContractId
                )
            }
            .flatMap { [wallet, transactionBuilder, networkService] transaction, hashToSign in
                signer.sign(
                    hash: hashToSign,
                    walletPublicKey: wallet.publicKey
                )
                .tryMap { signature in
                    try transactionBuilder.buildForSend(
                        transaction: transaction,
                        signature: signature
                    )
                }
                .flatMap(networkService.submitTransaction)
                .map(\.id)
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

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        networkService.getRCLimit()
            .tryMap { [blockchain = wallet.blockchain] rcLimit in
                guard let rcLimit = rcLimit.decimal else {
                    throw BlockchainSdkError.failedToGetFee
                }
                return Fee(
                    Amount(
                        type: .feeResource(.mana),
                        currencySymbol: FeeResourceType.mana.rawValue,
                        value: rcLimit / blockchain.decimalValue,
                        decimals: blockchain.decimalCount
                    )
                )
            }
            .map { [$0] }
            .eraseToAnyPublisher()
    }
}
