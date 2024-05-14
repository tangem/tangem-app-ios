//
//  WalletModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

extension WalletModel {
    static let mockETH = WalletModel(
        walletManager: EthereumWalletManagerMock(),
        transactionHistoryService: nil,
        amountType: .coin,
        shouldPerformHealthCheck: false,
        isCustom: false
    )
}

class EthereumWalletManagerMock: WalletManager {
    var cardTokens: [BlockchainSdk.Token] { [] }

    func update() {}

    func updatePublisher() -> AnyPublisher<BlockchainSdk.WalletManagerState, Never> {
        Empty().eraseToAnyPublisher()
    }

    func setNeedsUpdate() {}

    func removeToken(_ token: BlockchainSdk.Token) {}

    func addToken(_ token: BlockchainSdk.Token) {}

    func addTokens(_ tokens: [BlockchainSdk.Token]) {}

    var wallet: BlockchainSdk.Wallet = .init(blockchain: .ethereum(testnet: false), addresses: [:])
    var walletPublisher: AnyPublisher<BlockchainSdk.Wallet, Never> { .just(output: wallet) }
    var statePublisher: AnyPublisher<BlockchainSdk.WalletManagerState, Never> { .just(output: .initial) }
    var currentHost: String { "" }
    var outputsCount: Int? { nil }

    func send(_ transaction: BlockchainSdk.Transaction, signer: BlockchainSdk.TransactionSigner) -> AnyPublisher<BlockchainSdk.TransactionSendResult, SendTxError> {
        Empty().eraseToAnyPublisher()
    }

    func validate(fee: BlockchainSdk.Fee) throws {}
    func validate(amount: BlockchainSdk.Amount) throws {}
    var allowsFeeSelection: Bool { true }

    func getFee(amount: BlockchainSdk.Amount, destination: String) -> AnyPublisher<[BlockchainSdk.Fee], Error> {
        .just(output: [])
    }
}
