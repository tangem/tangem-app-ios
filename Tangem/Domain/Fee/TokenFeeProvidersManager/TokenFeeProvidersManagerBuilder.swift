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

        // Gasless fee tokens is empty
        guard !availableTokens.isEmpty else {
            return []
        }

        guard let currentUserWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletModel.userWalletId }) else {
            assertionFailure("User wallet not found")
            return []
        }

        let walletModels = if FeatureProvider.isAvailable(.accounts) {
            walletModel.account?.walletModelsManager.walletModels ?? []
        } else {
            AccountsFeatureAwareWalletModelsResolver.walletModels(for: currentUserWalletModel)
        }

        // Exclude wallet models with active Yield mode:
        // their token balance is deposited into the Yield smart contract, so on-chain balance checks
        // will report insufficient funds. This breaks our fee token gas limit estimation (we probe with
        // a small amount, e.g. 10_000 base units), causing the node to reject the estimate.
        let availableWalletModels = walletModels.filter { model in
            model.yieldModuleManager?.state?.state.isEffectivelyActive != true
        }

        let gaslessFeeWalletModels = availableWalletModels.filter { walletModel in
            availableTokens.contains(where: { $0.tokenAddress == walletModel.tokenItem.contractAddress })
        }

        let gaslessTokenFeeProviders: [any TokenFeeProvider] = gaslessFeeWalletModels.map { feeWalletModel in
            .gasless(walletModel: walletModel, feeWalletModel: feeWalletModel, supportingOptions: supportingOptions)
        }

        return gaslessTokenFeeProviders
    }
}
