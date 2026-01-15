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

extension CommonWalletModel {
    static var mockETH = {
        let walletManager = EthereumWalletManagerMock()
        let blockchain = walletManager.wallet.blockchain
        let derivationPath = walletManager.wallet.publicKey.derivationPath
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)
        let tokenItem = TokenItem.blockchain(blockchainNetwork)
        let mobileWalletInfo = MobileWalletInfo(
            hasMnemonicBackup: false,
            hasICloudBackup: false,
            accessCodeStatus: .none,
            keys: []
        )

        let config = UserWalletConfigFactory().makeConfig(mobileWalletInfo: mobileWalletInfo)
        let hwLimitationsUtil = HardwareLimitationsUtil(config: config)
        let sendAvailabilityProvider = TransactionSendAvailabilityProvider(hardwareLimitationsUtil: hwLimitationsUtil)

        return CommonWalletModel(
            userWalletId: .init(with: Data()),
            tokenItem: tokenItem,
            walletManager: EthereumWalletManagerMock(),
            stakingManager: StakingManagerMock(),
            featureManager: WalletModelFeaturesManagerMock(),
            transactionHistoryService: nil,
            receiveAddressService: DummyReceiveAddressService(addressInfos: []),
            sendAvailabilityProvider: sendAvailabilityProvider,
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
        addresses: [.default: PlainAddress(
            value: "0xtestaddress",
            publicKey: Wallet.PublicKey(seedKey: Data(), derivationType: .none),
            type: .default
        )]
    )
    var state: WalletManagerState { .initial }
    var walletPublisher: AnyPublisher<BlockchainSdk.Wallet, Never> { .just(output: wallet) }
    var statePublisher: AnyPublisher<BlockchainSdk.WalletManagerState, Never> { .just(output: state) }
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
