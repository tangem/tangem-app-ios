//
//  WalletModelBalancesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// MARK: - WalletModelBalancesProvider

protocol WalletModelBalancesProvider {
    var availableBalanceProvider: TokenBalanceProvider { get }
    var stakingBalanceProvider: TokenBalanceProvider { get }
    var totalTokenBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var fiatStakingBalanceProvider: TokenBalanceProvider { get }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
}

final class CommonWalletModelBalancesProvider: WalletModelBalancesProvider {
    let availableBalanceProvider: TokenBalanceProvider
    let stakingBalanceProvider: TokenBalanceProvider
    let totalTokenBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let fiatStakingBalanceProvider: TokenBalanceProvider
    let fiatTotalTokenBalanceProvider: TokenBalanceProvider

    init(
        walletModelId: WalletModelId,
        tokenItem: TokenItem,
        availableTokenBalanceProviderInput: AvailableTokenBalanceProviderInput,
        stakingTokenBalanceProviderInput: StakingTokenBalanceProviderInput,
        fiatTokenBalanceProviderInput: FiatTokenBalanceProviderInput,
        tokenBalancesRepository: TokenBalancesRepository
    ) {
        availableBalanceProvider = AvailableTokenBalanceProvider(
            input: availableTokenBalanceProviderInput,
            walletModelId: walletModelId,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository
        )

        stakingBalanceProvider = StakingTokenBalanceProvider(
            input: stakingTokenBalanceProviderInput,
            walletModelId: walletModelId,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository
        )

        totalTokenBalanceProvider = TotalTokenBalanceProvider(
            tokenItem: tokenItem,
            availableBalanceProvider: availableBalanceProvider,
            stakingBalanceProvider: stakingBalanceProvider
        )

        fiatAvailableBalanceProvider = FiatTokenBalanceProvider(
            input: fiatTokenBalanceProviderInput,
            cryptoBalanceProvider: availableBalanceProvider
        )

        fiatStakingBalanceProvider = FiatTokenBalanceProvider(
            input: fiatTokenBalanceProviderInput,
            cryptoBalanceProvider: stakingBalanceProvider
        )

        fiatTotalTokenBalanceProvider = FiatTokenBalanceProvider(
            input: fiatTokenBalanceProviderInput,
            cryptoBalanceProvider: totalTokenBalanceProvider
        )
    }
}
