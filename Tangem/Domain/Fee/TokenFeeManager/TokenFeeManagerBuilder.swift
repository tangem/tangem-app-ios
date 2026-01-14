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
        let coinTokenFeeProvider = TokenFeeProviderBuilder.makeTokenFeeProvider(walletModel: walletModel)
        var feeProviders = [coinTokenFeeProvider] // Main

        if FeatureProvider.isAvailable(.gaslessTransactions) {
            let availableTokens = gaslessTransactionsNetworkManager.availableFeeTokens
                .filter { $0.chainId == walletModel.tokenItem.blockchain.chainId }

            if !availableTokens.isEmpty {
                let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders(availableTokens: availableTokens)
                feeProviders.append(contentsOf: gaslessTokenFeeProviders)
            }
        }

        return TokenFeeManager(feeProviders: feeProviders, initialSelectedProvider: coinTokenFeeProvider)
    }

    private func makeGaslessTokenFeeProviders(availableTokens: [GaslessTransactionsNetworkManager.FeeToken]) -> [any TokenFeeProvider] {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletModel.userWalletId }) else {
            assertionFailure("User wallet not found")
            return []
        }

        let gaslessFeeWalletModels = AccountsFeatureAwareWalletModelsResolver
            .walletModels(for: userWalletModel)
            .filter { walletModel in
                availableTokens.contains(where: { $0.tokenAddress == walletModel.tokenItem.contractAddress })
            }

        let gaslessTokenFeeProviders = gaslessFeeWalletModels.map { feeWalletModel in
            TokenFeeProviderBuilder.makeGaslessTokenFeeProvider(walletModel: walletModel, feeWalletModel: feeWalletModel)
        }

        return gaslessTokenFeeProviders
    }
}
