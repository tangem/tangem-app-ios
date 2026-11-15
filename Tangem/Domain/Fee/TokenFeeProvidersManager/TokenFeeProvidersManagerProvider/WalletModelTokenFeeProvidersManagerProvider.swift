//
//  WalletModelTokenFeeProvidersManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct WalletModelTokenFeeProvidersManagerProvider {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    private let walletModel: any WalletModel
    private let tokenFeeLoaderProvider: any TokenFeeLoaderProvider
    private let purpose: Purpose
    private let transactionReleasesSourceToken: Bool
    private let providerSwitching: CommonTokenFeeProvidersManager.ProviderSwitching

    init(
        walletModel: any WalletModel,
        purpose: Purpose,
        transactionReleasesSourceToken: Bool = false,
        providerSwitching: CommonTokenFeeProvidersManager.ProviderSwitching = .always
    ) {
        self.walletModel = walletModel
        tokenFeeLoaderProvider = WalletModelTokenFeeLoaderProvider(walletModel: walletModel)
        self.purpose = purpose
        self.transactionReleasesSourceToken = transactionReleasesSourceToken
        self.providerSwitching = providerSwitching
    }
}

// MARK: - Purpose

extension WalletModelTokenFeeProvidersManagerProvider {
    enum Purpose {
        case transfer(TokenFeeProviderSupportingOptions)
        case swap

        var supportingOptions: TokenFeeProviderSupportingOptions {
            switch self {
            case .transfer(let supportingOptions): supportingOptions
            case .swap: .swap
            }
        }

        var includesSponsoredFee: Bool {
            switch self {
            case .transfer: false
            case .swap: true
            }
        }
    }
}

// MARK: - TokenFeeProvidersManagerProvider

extension WalletModelTokenFeeProvidersManagerProvider: TokenFeeProvidersManagerProvider {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager {
        let coinTokenFeeProvider = makeMainTokenFeeProvider()
        var feeProviders = [coinTokenFeeProvider]

        if walletModel.tokenItem.token?.metadata.kind == .fungible {
            let gaslessTokenFeeProviders = makeGaslessTokenFeeProviders()
            feeProviders.append(contentsOf: gaslessTokenFeeProviders)
        }

        if let sponsoredTokenFeeProvider = makeSponsoredTokenFeeProvider() {
            feeProviders.append(sponsoredTokenFeeProvider)
        }

        let initialSelectedProvider = prepareInitialTokenFeeProvider(main: coinTokenFeeProvider, all: feeProviders)
        return CommonTokenFeeProvidersManager(
            feeProviders: feeProviders,
            initialSelectedProvider: initialSelectedProvider,
            ownerAddress: walletModel.defaultAddressString,
            providerSwitching: providerSwitching
        )
    }
}

// MARK: - Prepare initial token

extension WalletModelTokenFeeProvidersManagerProvider {
    func availableGaslessTokenAddresses() -> [String] {
        if case .tron(testnet: false) = walletModel.tokenItem.blockchain {
            guard let contractAddress = walletModel.tokenItem.contractAddress else {
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

        if let sponsoredProvider = all.first(where: { $0.payer == .tangem }) {
            return sponsoredProvider
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

    func minimumRequiredGaslessFeeTokenBalance() -> Decimal? {
        guard case .tron(testnet: false) = walletModel.tokenItem.blockchain,
              walletModel.tronAccountActivationStateProvider?.isAccountActivated == false else {
            return nil
        }

        return Constants.tronGaslessActivationMinimumBalance
    }
}

// MARK: - Private

private extension WalletModelTokenFeeProvidersManagerProvider {
    func makeMainTokenFeeProvider() -> any TokenFeeProvider {
        let tokenFeeLoader = tokenFeeLoaderProvider.makeMainTokenFeeLoader()
        let customFeeProvider = tokenFeeLoaderProvider.makeCustomFeeProvider()
        let feeTokenItemBalanceProvider = walletModel.feeTokenItemBalanceProvider

        return CommonTokenFeeProvider(
            feeTokenItem: walletModel.feeTokenItem,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider,
            feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
            supportingOptions: purpose.supportingOptions,
            payer: .user,
        )
    }

    func makeGaslessTokenFeeProviders() -> [any TokenFeeProvider] {
        let availableTokenAddresses = availableGaslessTokenAddresses()

        guard !availableTokenAddresses.isEmpty else {
            return []
        }

        let currentAccountWalletModels = walletModel.account?.walletModelsManager.walletModels ?? []

        let sourceTokenChainId = walletModel.tokenItem.blockchain.chainId

        // Wallet models eligible for gasless fees: same chain as the source token and a supported token address.
        let gaslessFeeWalletModels: [any WalletModel] = currentAccountWalletModels.compactMap { model in
            // On EVM the service returns fee-token addresses lowercased while the wallet stores them in
            // EIP-55 checksum form, so compare case-insensitively. TRON base58 addresses are case-sensitive
            // and unaffected — a wrong-case variant simply fails the base58check and is filtered out.
            guard
                let contractAddress = model.tokenItem.contractAddress,
                availableTokenAddresses.contains(where: { $0.caseInsensitiveEquals(to: contractAddress) }),
                model.tokenItem.blockchain.chainId == sourceTokenChainId
            else { return nil }

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

            let isFeeTokenFundedByTransaction = transactionReleasesSourceToken && feeTokenItem == walletModel.tokenItem
            let yieldFeeContext = isFeeTokenFundedByTransaction
                ? nil
                : makeYieldFeeContext(feeWalletModel: feeWalletModel, feeTokenItemBalanceProvider: feeTokenItemBalanceProvider)

            guard let tokenFeeLoader = tokenFeeLoaderProvider.makeGaslessTokenFeeLoader(
                feeToken: feeToken,
                yieldFeeContext: yieldFeeContext,
                isFeeTokenFundedByTransaction: isFeeTokenFundedByTransaction
            ) else {
                return nil
            }

            return CommonTokenFeeProvider(
                feeTokenItem: feeTokenItem,
                tokenFeeLoader: tokenFeeLoader,
                customFeeProvider: .none,
                feeTokenItemBalanceProvider: feeTokenItemBalanceProvider,
                supportingOptions: .exactly([.market]),
                minimumRequiredBalance: minimumRequiredGaslessFeeTokenBalance(),
                payer: .user,
            )
        }

        return gaslessTokenFeeProviders
    }

    func makeSponsoredTokenFeeProvider() -> (any TokenFeeProvider)? {
        guard purpose.includesSponsoredFee, FeatureProvider.isAvailable(.solanaGasless) else {
            return nil
        }

        guard let tokenFeeLoader = tokenFeeLoaderProvider.makeSolanaGaslessTokenFeeLoader() else {
            return nil
        }

        guard gaslessTransactionsNetworkManager.cachedSolanaFeePayer != nil else {
            _ = Task { [gaslessTransactionsNetworkManager] in
                _ = await gaslessTransactionsNetworkManager.solanaFeePayer
            }
            return nil
        }

        return CommonTokenFeeProvider(
            feeTokenItem: walletModel.feeTokenItem,
            tokenFeeLoader: tokenFeeLoader,
            customFeeProvider: .none,
            feeTokenItemBalanceProvider: walletModel.feeTokenItemBalanceProvider,
            supportingOptions: .exactly([.market]),
            payer: .tangem
        )
    }

    func makeYieldFeeContext(
        feeWalletModel: any WalletModel,
        feeTokenItemBalanceProvider: TokenBalanceProvider
    ) -> GaslessYieldFeeContext? {
        guard let activeInfo = feeWalletModel.yieldModuleManager?.state?.state.activeInfo else {
            return nil
        }

        return GaslessYieldFeeContext(
            yieldContractAddress: activeInfo.yieldContractAddress,
            yieldModuleBalance: activeInfo.yieldModuleBalanceValue,
            feeTokenBalanceProvider: feeTokenItemBalanceProvider,
            versionChecker: feeWalletModel.yieldModuleManager?.versionChecker,
            versionResolver: feeWalletModel.yieldModuleManager?.versionResolver
        )
    }
}

private extension WalletModelTokenFeeProvidersManagerProvider {
    enum Constants {
        static let tronGaslessActivationMinimumBalance: Decimal = 5
    }
}
