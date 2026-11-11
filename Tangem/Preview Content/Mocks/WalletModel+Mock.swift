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
import TangemFoundation

extension CommonWalletModel {
    static var mockETH = {
        let walletManager = EthereumWalletManagerMock()
        let blockchain = walletManager.wallet.blockchain
        let derivationPath = walletManager.wallet.publicKey.derivationPath
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)
        let tokenItem = TokenItem.blockchain(blockchainNetwork)

        return CommonWalletModel(
            userWalletId: .init(with: Data()),
            tokenItem: tokenItem,
            walletManager: walletManager,
            stakingManager: StakingManagerMock(),
            isYieldModuleSupported: true,
            featureManager: WalletModelFeaturesManagerMock(),
            pendingTransactionsProvider: CommonPendingTransactionsProvider(walletProvider: walletManager, tokenItem: tokenItem),
            transactionHistoryUpdater: TransactionHistoryUpdater(),
            transactionHistoryService: nil,
            receiveAddressService: DummyReceiveAddressService(addressInfos: []),
            tokenBalancesRepository: TokenBalancesRepositoryMock(),
            isCustom: false
        )
    }()
}

class EthereumWalletManagerMock: WalletManager {
    var cardTokens: [BlockchainSdk.Token] { [] }

    func setNeedsUpdate() {}
    func update() async {}

    func removeToken(_ token: BlockchainSdk.Token) {}
    func addToken(_ token: BlockchainSdk.Token) {}

    var wallet: BlockchainSdk.Wallet = .init(
        blockchain: .ethereum(testnet: false),
        publicKey: Wallet.PublicKey(seedKey: Data(), derivationType: .none),
        addressesProvider: CommonAddressesProvider(
            defaultAddress: PlainAddress(
                value: "0xtestaddress",
                type: .default
            )
        )
    )
    var state: WalletManagerState { .initial }
    var walletPublisher: AnyPublisher<BlockchainSdk.Wallet, Never> { .just(output: wallet) }
    var statePublisher: AnyPublisher<BlockchainSdk.WalletManagerState, Never> { .just(output: state) }
    func update(wallet: BlockchainSdk.Wallet) throws {}

    var currentHost: String { "" }
    var outputsCount: Int? { nil }

    func send(_ transaction: BlockchainSdk.Transaction, signer: BlockchainSdk.TransactionSigner) -> AnyPublisher<BlockchainSdk.TransactionSendResult, SendTxError> {
        .empty
    }

    func updateWalletManager(address: String) async throws {}

    func getFee(amount: BlockchainSdk.Amount, destination: String) -> AnyPublisher<[BlockchainSdk.Fee], Error> {
        .just(output: [])
    }
}
