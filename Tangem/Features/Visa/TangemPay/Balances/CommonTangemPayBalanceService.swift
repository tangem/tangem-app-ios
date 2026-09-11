//
//  CommonTangemPayBalanceService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemFoundation
import TangemPay

final class CommonTangemPayBalanceService: TangemPayBalancesService {
    // MARK: - TangemPayBalancesProvider

    lazy var totalTokenBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject,
        value: \.fiat.availableBalance,
        cachesBalance: true
    )

    lazy var availableBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject,
        value: \.availableForWithdrawal.amount,
        cachesBalance: false
    )

    lazy var fiatAvailableBalanceProvider: any TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: availableBalanceProvider
    )

    lazy var fiatTotalTokenBalanceProvider: TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: totalTokenBalanceProvider
    )

    lazy var fixedFiatTotalTokenBalanceProvider: TokenBalanceProvider = TangemPayFiatTokenBalanceProvider(
        cryptoBalanceProvider: totalTokenBalanceProvider
    )

    func availableBalanceProvider(for accountToken: TangemPayAccountToken) -> TokenBalanceProvider {
        guard let chainId = accountToken.chainId, let contractAddress = accountToken.tokenItem.contractAddress else {
            return availableBalanceProvider
        }

        return TangemPayTokenBalanceProvider(
            tokenItem: accountToken.tokenItem,
            tokenBalancesRepository: tokenBalancesRepository,
            balanceSubject: balanceSubject,
            value: { $0.availableForWithdrawal(chainId: chainId, tokenContractAddress: contractAddress) ?? .zero },
            cachesBalance: false
        )
    }

    func fiatAvailableBalanceProvider(for accountToken: TangemPayAccountToken) -> TokenBalanceProvider {
        // The account holds USD stables only, so the account's USDC rate stands in
        // for every per-network token.
        FiatTokenBalanceProvider(
            input: fiatRateProvider,
            cryptoBalanceProvider: availableBalanceProvider(for: accountToken)
        )
    }

    private let customerInfoManagementService: any CustomerInfoManagementService
    private let tokenBalancesRepository: any TokenBalancesRepository

    private let tokenItem = TangemPayUtilities.usdcTokenItem
    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>(nil)
    private var loadedNetworks: [TangemPayBalance.Network] = []

    private lazy var fiatRateProvider: FiatRateProvider = CommonFiatRateProvider(
        tokenItem: tokenItem
    )

    init(
        customerInfoManagementService: any CustomerInfoManagementService,
        tokenBalancesRepository: any TokenBalancesRepository
    ) {
        self.customerInfoManagementService = customerInfoManagementService
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - TangemPayBalancesService

extension CommonTangemPayBalanceService {
    var networks: [TangemPayBalance.Network] {
        loadedNetworks
    }

    func loadBalance() async {
        do {
            balanceSubject.send(.loading)
            let balance = try await customerInfoManagementService.getBalance()
            loadedNetworks = balance.networks
            balanceSubject.send(.success(balance))

            fiatRateProvider.updateRate()
        } catch {
            balanceSubject.send(.failure(error))
        }
    }
}
