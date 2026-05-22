//
//  CommonWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemStaking
import TangemFoundation

struct CommonWalletModelsFactory {
    private let config: UserWalletConfig
    private let userWalletId: UserWalletId
    private let walletModelFeaturesManagerFactory: WalletModelFeaturesManagerFactory
    private let transactionHistoryServiceProvider: TransactionHistoryServiceProvider

    init(
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        walletModelFeaturesManagerFactory: WalletModelFeaturesManagerFactory,
        transactionHistoryServiceProvider: TransactionHistoryServiceProvider
    ) {
        self.config = config
        self.userWalletId = userWalletId
        self.walletModelFeaturesManagerFactory = walletModelFeaturesManagerFactory
        self.transactionHistoryServiceProvider = transactionHistoryServiceProvider
    }

    private func isMainCoinCustom(
        blockchainDerivationPath: DerivationPath?,
        targetAccountDerivationPath: DerivationPath?
    ) -> Bool {
        guard let blockchainDerivationPath else {
            // Blockchain can't be custom if its derivation path is absent
            return false
        }

        guard let targetAccountDerivationPath else {
            // No target path means no HD wallets support - not custom
            return false
        }

        return blockchainDerivationPath != targetAccountDerivationPath
    }

    func makeStakingManager(publicKey: Data, tokenItem: TokenItem, address: String) -> StakingManager? {
        let featureProvider = StakingFeatureProvider(config: config)

        guard let integrationId = featureProvider.yieldId(for: tokenItem),
              let item = tokenItem.stakingTokenItem else {
            return nil
        }

        let wallet = StakingWallet(
            item: item,
            address: address,
            publicKey: publicKey
        )
        return StakingDependenciesFactory().makeStakingManager(integrationId: integrationId, wallet: wallet)
    }

    private func makeReceiveAddressService(tokenItem: TokenItem, addresses: [Address]) -> ReceiveAddressService {
        let factory = DomainNameAddressResolverFactoryProvider().factory
        let domainAddressResolver = factory.makeAddressResolver(for: tokenItem.blockchain)

        return CommonReceiveAddressService(addresses: addresses, domainAddressResolver: domainAddressResolver)
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(
        for types: [Amount.AmountType],
        walletManager: WalletManager,
        blockchainNetwork: BlockchainNetwork,
        targetAccountDerivationPath: DerivationPath?
    ) -> [any WalletModel] {
        var models: [any WalletModel] = []

        let isMainCoinCustom = isMainCoinCustom(
            blockchainDerivationPath: blockchainNetwork.derivationPath,
            targetAccountDerivationPath: targetAccountDerivationPath
        )
        let sendAvailabilityProvider = TransactionSendAvailabilityProvider(
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: config)
        )
        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

        if types.contains(.coin) {
            let tokenItem: TokenItem = .blockchain(blockchainNetwork)
            let transactionHistoryService = transactionHistoryServiceProvider.makeTransactionHistoryService(
                tokenItem: tokenItem,
                walletManager: walletManager
            )
            let receiveAddressService = makeReceiveAddressService(
                tokenItem: tokenItem,
                addresses: walletManager.wallet.addresses
            )

            let featureManager = walletModelFeaturesManagerFactory.makeWalletModelFeaturesManager(
                tokenItem: tokenItem,
                walletManager: walletManager
            )

            let mainCoinModel = CommonWalletModel(
                userWalletId: userWalletId,
                tokenItem: tokenItem,
                walletManager: walletManager,
                stakingManager: makeStakingManager(
                    publicKey: walletManager.wallet.publicKey.blockchainKey,
                    tokenItem: tokenItem,
                    address: walletManager.wallet.address
                ),
                featureManager: featureManager,
                transactionHistoryService: transactionHistoryService,
                receiveAddressService: receiveAddressService,
                sendAvailabilityProvider: sendAvailabilityProvider,
                tokenBalancesRepository: tokenBalancesRepository,
                isCustom: isMainCoinCustom
            )

            mainCoinModel.initializeLazyProperties()
            models.append(mainCoinModel)
        }

        walletManager.cardTokens.forEach { token in
            let amountType: Amount.AmountType = .token(value: token)
            if types.contains(amountType) {
                let isTokenCustom = isMainCoinCustom || token.id == nil
                let tokenItem: TokenItem = .token(token, blockchainNetwork)
                let transactionHistoryService = transactionHistoryServiceProvider.makeTransactionHistoryService(
                    tokenItem: tokenItem,
                    walletManager: walletManager
                )
                let receiveAddressService = makeReceiveAddressService(
                    tokenItem: tokenItem,
                    addresses: walletManager.wallet.addresses
                )
                let featureManager = walletModelFeaturesManagerFactory.makeWalletModelFeaturesManager(
                    tokenItem: tokenItem,
                    walletManager: walletManager
                )
                let tokenModel = CommonWalletModel(
                    userWalletId: userWalletId,
                    tokenItem: tokenItem,
                    walletManager: walletManager,
                    stakingManager: makeStakingManager(
                        publicKey: walletManager.wallet.publicKey.blockchainKey,
                        tokenItem: tokenItem,
                        address: walletManager.wallet.address
                    ),
                    featureManager: featureManager,
                    transactionHistoryService: transactionHistoryService,
                    receiveAddressService: receiveAddressService,
                    sendAvailabilityProvider: sendAvailabilityProvider,
                    tokenBalancesRepository: tokenBalancesRepository,
                    isCustom: isTokenCustom
                )
                tokenModel.initializeLazyProperties()
                models.append(tokenModel)
            }
        }

        return models
    }
}
