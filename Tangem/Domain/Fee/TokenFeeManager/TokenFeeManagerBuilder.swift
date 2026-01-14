//
//  TokenFeeManagerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TokenFeeManagerBuilder {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func makeTokenFeeManager() -> TokenFeeManager {
        let coinTokenFeeProvider = makeMainTokenFeeProvider()
        var feeProviders = [coinTokenFeeProvider]

        // Only a token sending support gasless fee
        if FeatureProvider.isAvailable(.gaslessTransactions), walletModel.tokenItem.isToken {
            let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders()
            feeProviders.append(contentsOf: gaslessTokenFeeProviders)
        }

        return TokenFeeManager(feeProviders: feeProviders, initialSelectedProvider: coinTokenFeeProvider)
    }
}

// MARK: - Private

private extension TokenFeeManagerBuilder {
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
            availableTokenBalanceProvider: feeWalletModel.availableBalanceProvider,
            tokenFeeLoader: feeWalletModel.tokenFeeLoader,
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

        let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: currentUserWalletModel)
        let gaslessFeeWalletModels = walletModels.filter { walletModel in
            availableTokens.contains(where: { $0.tokenAddress == walletModel.tokenItem.contractAddress })
        }

        let gaslessTokenFeeProviders: [any TokenFeeProvider] = gaslessFeeWalletModels.map { feeWalletModel in
            .gasless(walletModel: walletModel, feeWalletModel: feeWalletModel)
        }

        return gaslessTokenFeeProviders
    }
}
