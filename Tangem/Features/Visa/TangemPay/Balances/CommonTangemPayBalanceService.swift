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
        keyPath: \.fiat.availableBalance,
        cachesBalance: true
    )

    // Does NOT cache. The token balances repository is keyed by (walletModelId, .available)
    // and totalTokenBalanceProvider above already uses that slot to persist
    // `fiat.availableBalance`. Letting this provider also write would last-writer-win the
    // slot with `availableForWithdrawal.amount` (often 0 with multiple cards) and the UI's
    // `.loading(cached:)` render would briefly show $0 between every refresh — visible blink.
    // This provider only feeds withdraw-availability / swap checks that read `.balanceType`
    // directly, never `cachedBalance()`, so suppressing the cache write is safe.
    lazy var availableBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject,
        keyPath: \.availableForWithdrawal.amount,
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

    private let customerInfoManagementService: any CustomerInfoManagementService
    private let tokenBalancesRepository: any TokenBalancesRepository

    private let tokenItem = TangemPayUtilities.usdcTokenItem
    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>(nil)

    /// Provider / Storage  to load `FiatRate` for `AppCurrency`
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
    func loadBalance() async {
        do {
            balanceSubject.send(.loading)
            let balance = try await customerInfoManagementService.getBalance()
            balanceSubject.send(.success(balance))

            fiatRateProvider.updateRate()
        } catch {
            balanceSubject.send(.failure(error))
        }
    }
}
