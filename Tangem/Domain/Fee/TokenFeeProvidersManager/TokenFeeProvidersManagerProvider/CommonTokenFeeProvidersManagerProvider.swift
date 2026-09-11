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

    let walletModel: any WalletModel
    let supportingOptions: TokenFeeProviderSupportingOptions
    private let isFeatureAvailable: (Feature) -> Bool

    init(
        walletModel: any WalletModel,
        supportingOptions: TokenFeeProviderSupportingOptions = .all,
        isFeatureAvailable: @escaping (Feature) -> Bool = FeatureProvider.isAvailable
    ) {
        self.walletModel = walletModel
        self.supportingOptions = supportingOptions
        self.isFeatureAvailable = isFeatureAvailable
    }
}

// MARK: - TokenFeeProvidersManagerProvider

extension CommonTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let coinTokenFeeProvider = makeMainTokenFeeProvider()
        var feeProviders = [coinTokenFeeProvider]

        if walletModel.tokenItem.token?.metadata.kind == .fungible {
            let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders()
            feeProviders.append(contentsOf: gaslessTokenFeeProviders)
        }

        let initialSelectedProvider = prepareInitialTokenFeeProvider(main: coinTokenFeeProvider, all: feeProviders)
        return CommonTokenFeeProvidersManager(
            feeProviders: feeProviders,
            initialSelectedProvider: initialSelectedProvider,
            ownerAddress: walletModel.defaultAddressString
        )
    }
}

// MARK: - Prepare initial token

extension CommonTokenFeeProvidersManagerProvider {
    func availableGaslessTokenAddresses() -> [String] {
        if case .tron(testnet: false) = walletModel.tokenItem.blockchain {
            guard isFeatureAvailable(.tronGasless),
                  walletModel.tronAccountActivationStateProvider?.isAccountActivated == true,
                  let contractAddress = walletModel.tokenItem.contractAddress else {
                return []
            }

            // Tron gasless supports only for the same token being sent.
            return gaslessTransactionsNetworkManager.availableTronFeeTokens
                .filter { $0.address == contractAddress }
                .map(\.address)
        }

        return gaslessTransactionsNetworkManager.availableFeeTokens
            .filter { $0.chainId == walletModel.tokenItem.blockchain.chainId }
            .map(\.tokenAddress)
    }

    func prepareInitialTokenFeeProvider(main: any TokenFeeProvider, all: [any TokenFeeProvider]) -> any TokenFeeProvider {
        // Early exit when we have only main provider
        guard all.hasMultipleFeeProviders else {
            return main
        }

        // Tron: prefer gasless when the available fee token has a positive balance.
        // Gasless fees are lower than TRX in most cases.
        // Temporary solution until we implement multi-token gas estimation.
        if case .tron(testnet: false) = walletModel.tokenItem.blockchain {
            return all.first(where: {
                $0.feeTokenItem != main.feeTokenItem && ($0.balanceFeeTokenState.loaded ?? 0) > 0
            }) ?? main
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
}

// MARK: - Private

private extension CommonTokenFeeProvidersManagerProvider {
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
        let availableTokenAddresses = availableGaslessTokenAddresses()

        guard !availableTokenAddresses.isEmpty else {
            return []
        }

        let currentAccountWalletModels = walletModel.account?.walletModelsManager.walletModels ?? []

        let sourceTokenChainId = walletModel.tokenItem.blockchain.chainId

        // Wallet models eligible for gasless fees: same chain as the source token, token address is supported,
        // and active Yield Mode is included only for the dedicated gasless-yield flow.
        let gaslessFeeWalletModels: [any WalletModel] = currentAccountWalletModels.compactMap { model in
            guard let contractAddress = model.tokenItem.contractAddress else { return nil }
            guard availableTokenAddresses.contains(contractAddress) else { return nil }
            guard model.tokenItem.blockchain.chainId == sourceTokenChainId else { return nil }
            if model.yieldModuleManager?.state?.state.isEffectivelyActive == true {
                guard FeatureProvider.isAvailable(.gaslessYieldFee) else { return nil }
            }
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

            let yieldFeeContext = makeYieldFeeContext(
                feeWalletModel: feeWalletModel,
                feeTokenItemBalanceProvider: feeTokenItemBalanceProvider
            )

            guard let tokenFeeLoader = walletModel.tokenFeeLoaderBuilder.makeGaslessTokenFeeLoader(
                feeToken: feeToken,
                yieldFeeContext: yieldFeeContext
            ) else {
                assertionFailure("Try to create gasless TokenFeeProvider with invalid tokenItem")
                return nil
            }

            return CommonTokenFeeProvider(
                feeTokenItem: feeTokenItem,
                tokenFeeLoader: tokenFeeLoader,
                customFeeProvider: .none,
                feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
                supportingOptions: .exactly([.market]),
            )
        }

        return gaslessTokenFeeProviders
    }

    func makeYieldFeeContext(
        feeWalletModel: any WalletModel,
        feeTokenItemBalanceProvider: TokenBalanceProvider
    ) -> GaslessYieldFeeContext? {
        guard FeatureProvider.isAvailable(.gaslessYieldFee),
              let activeInfo = feeWalletModel.yieldModuleManager?.state?.state.activeInfo else {
            return nil
        }

        return GaslessYieldFeeContext(
            yieldContractAddress: activeInfo.yieldContractAddress,
            yieldModuleBalance: activeInfo.yieldModuleBalanceValue,
            feeTokenBalanceProvider: feeTokenItemBalanceProvider,
            versionChecker: feeWalletModel.yieldModuleManager?.versionChecker
        )
    }
}
