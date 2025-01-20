//
//  AlephiumWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AlephiumWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        true
    }

    // MARK: - Private Implementation

    private let networkService: AlephiumNetworkService
    private let transactionBuilder: AlephiumTransactionBuilder

    // MARK: - Init

    init(wallet: Wallet, networkService: AlephiumNetworkService, transactionBuilder: AlephiumTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Manager Implementation

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        // [REDACTED_TODO_COMMENT]
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        // [REDACTED_TODO_COMMENT]
        return .anyFail(error: WalletError.failedToBuildTx)
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        // [REDACTED_TODO_COMMENT]
        return .anyFail(error: SendTxError(error: WalletError.failedToSendTx))
    }

    // MARK: - Private Implementation
}
