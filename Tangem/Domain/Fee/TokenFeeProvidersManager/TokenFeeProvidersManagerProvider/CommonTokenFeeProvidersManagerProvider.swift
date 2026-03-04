//
//  CommonTokenFeeProvidersManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonTokenFeeProvidersManagerProvider {
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
}

// MARK: - TokenFeeProvidersManagerProvider

extension CommonTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let coinTokenFeeProvider = makeMainTokenFeeProvider()
        var feeProviders = [coinTokenFeeProvider]

        // Only a token sending support gasless fee
        if walletModel.tokenItem.isToken {
            let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders()
            feeProviders.append(contentsOf: gaslessTokenFeeProviders)
        }

        let initialSelectedProvider = prepareInitialTokenFeeProvider(main: coinTokenFeeProvider, all: feeProviders)
        return CommonTokenFeeProvidersManager(feeProviders: feeProviders, initialSelectedProvider: initialSelectedProvider)
    }
}

// MARK: - Private

private extension CommonTokenFeeProvidersManagerProvider {
    func prepareInitialTokenFeeProvider(main: any TokenFeeProvider, all: [any TokenFeeProvider]) -> any TokenFeeProvider {
        // Early exit when we have only main provider
        guard all.hasMultipleFeeProviders else {
            return main
        }

        // If main(coin) fee provider has zero balance then try to find gasless
        guard main.balanceFeeTokenState.loaded == .zero else {
            return main
        }

        // If we have same TokenFeeProvider as sending token.
        // It means we have positive balance on this token.
        // Then use it
        if let gaslessProvider = all[walletModel.tokenItem], (gaslessProvider.balanceFeeTokenState.loaded ?? 0) > 0 {
            return gaslessProvider
        }

        // Fallback to coin. In case we don't have any gasless providers.
        return main
    }

    func makeMainTokenFeeProvider() -> any TokenFeeProvider {
        let tokenFeeLoader = walletModel.tokenFeeLoaderBuilder.makeMainTokenFeeLoader()
        let customFeeProvider = walletModel.customFeeProviderBuilder.makeCustomFeeProvider()
        let feeTokenItemBalanceProvider = walletModel.feeTokenItemBalanceProvider

        return CommonTokenFeeProvider(
            feeTokenItem: walletModel.feeTokenItem,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider,
            feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
            supportingOptions: supportingOptions,
        )
    }

    func makeGaslessTokenFeeProviders() -> [any TokenFeeProvider] {
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

        let gaslessTokenFeeProviders: [any TokenFeeProvider] = gaslessFeeWalletModels.compactMap { feeWalletModel in
            // Important! The `feeTokenItem` is tokenItem, means USDT / USDC
            let feeTokenItem = feeWalletModel.tokenItem
            let feeTokenItemBalanceProvider = feeWalletModel.availableBalanceProvider

            guard let feeToken = feeTokenItem.token else {
                assertionFailure("Try to create gasless TokenFeeProvider with invalid tokenItem")
                return nil
            }

            guard let tokenFeeLoader = walletModel.tokenFeeLoaderBuilder.makeGaslessTokenFeeLoader(feeToken: feeToken) else {
                assertionFailure("Try to create gasless TokenFeeProvider with invalid tokenItem")
                return nil
            }

            return CommonTokenFeeProvider(
                feeTokenItem: feeTokenItem,
                tokenFeeLoader: tokenFeeLoader,
                // Gasless doesn't support custom fee
                customFeeProvider: .none,
                feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
                supportingOptions: supportingOptions,
            )
        }

        return gaslessTokenFeeProviders
    }
}
