//
//  TokenFeeProvidersManagerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TokenFeeProvidersManagerBuilder {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    let walletModel: any WalletModel
    let supportingOptions: TokenFeeProviderSupportingOptions

    init(walletModel: any WalletModel, supportingOptions: TokenFeeProviderSupportingOptions = .all) {
        self.walletModel = walletModel
        self.supportingOptions = supportingOptions
    }

    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let coinTokenFeeProvider = makeMainTokenFeeProvider()
        var feeProviders = [coinTokenFeeProvider]

        // Only a token sending support gasless fee
        if FeatureProvider.isAvailable(.gaslessTransactions), walletModel.tokenItem.isToken {
            let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders()
            feeProviders.append(contentsOf: gaslessTokenFeeProviders)
        }

        return CommonTokenFeeProvidersManager(feeProviders: feeProviders, initialSelectedProvider: coinTokenFeeProvider)
    }
}

// MARK: - Private

private extension TokenFeeProvidersManagerBuilder {
    private func makeMainTokenFeeProvider() -> any TokenFeeProvider {
        let feeWalletModelResult = try? WalletModelFinder.findWalletModel(
            userWalletId: walletModel.userWalletId,
            tokenItem: walletModel.feeTokenItem
        )

        guard let feeWalletModel = feeWalletModelResult?.walletModel else {
            assertionFailure("User wallet not found")
            return .empty(feeTokenItem: walletModel.feeTokenItem)
        }

        return .common(
            feeTokenItem: feeWalletModel.tokenItem,
            supportingOptions: supportingOptions,
            availableTokenBalanceProvider: feeWalletModel.availableBalanceProvider,
            tokenFeeLoader: walletModel.tokenFeeLoader,
            customFeeProvider: feeWalletModel.customFeeProvider
        )
    }

    private func makeGaslessTokenFeeProviders() -> [any TokenFeeProvider] {
        let availableTokens = gaslessTransactionsNetworkManager.availableFeeTokens
            .filter { $0.chainId == walletModel.tokenItem.blockchain.chainId }

        guard !availableTokens.isEmpty else {
            return []
        }

        guard let currentUserWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletModel.userWalletId }) else {
            assertionFailure("User wallet not found")
            return []
        }

        let currentAccountWalletModels = if FeatureProvider.isAvailable(.accounts) {
            walletModel.account?.walletModelsManager.walletModels ?? []
        } else {
            AccountsFeatureAwareWalletModelsResolver.walletModels(for: currentUserWalletModel)
        }

        let sourceTokenChainId = walletModel.tokenItem.blockchain.chainId
        let availableTokenAddresses: Set<String?> = Set(availableTokens.map { $0.tokenAddress })

        // Wallet models eligible for gasless fees: same chain as the source token, not in active Yield, and token address is supported
        let gaslessFeeWalletModels: [any WalletModel] = currentAccountWalletModels.compactMap { model in
            guard availableTokenAddresses.contains(model.tokenItem.contractAddress) else { return nil }
            guard model.tokenItem.blockchain.chainId == sourceTokenChainId else { return nil }
            guard !(model.yieldModuleManager?.state?.state.isEffectivelyActive ?? false) else { return nil }
            return model
        }

        let gaslessTokenFeeProviders: [any TokenFeeProvider] = gaslessFeeWalletModels.map { feeWalletModel in
            .gasless(walletModel: walletModel, feeWalletModel: feeWalletModel, supportingOptions: supportingOptions)
        }

        return gaslessTokenFeeProviders
    }
}
