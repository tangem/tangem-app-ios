//
//  YieldModePromoPositionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("YieldModePromoPosition mapping")
struct YieldModePromoPositionTests {
    @Test("Balances map to loaded, loading, missing derivation or failed")
    func mapsBalances() {
        #expect(YieldModePromoPosition.Balance(.loaded(5)) == .loaded(5))
        #expect(YieldModePromoPosition.Balance(.loading(nil)) == .loading)
        #expect(YieldModePromoPosition.Balance(.empty(.noData)) == .loading)
        #expect(YieldModePromoPosition.Balance(.empty(.noAccount(message: ""))) == .loaded(0))
        #expect(YieldModePromoPosition.Balance(.empty(.noDerivation)) == .missingDerivation)
        #expect(YieldModePromoPosition.Balance(.empty(.custom)) == .failed)
        #expect(YieldModePromoPosition.Balance(.failure(nil)) == .failed)
    }

    @Test("Yield Mode states map so that only a pending load keeps the promo waiting")
    func mapsYieldStates() {
        #expect(YieldModePromoPosition.YieldState(nil) == .loading)
        #expect(yieldState(.loading(cachedState: nil)) == .loading)
        #expect(yieldState(.loading(cachedState: .notActive(promoStatus: .undefined))) == .loading)
        #expect(yieldState(.notActive(promoStatus: .undefined)) == .notActive)
        #expect(yieldState(.failedToLoad(error: "", cachedState: nil)) == .failed)
        #expect(yieldState(.failedToLoad(error: "", cachedState: .notActive(promoStatus: .undefined))) == .failed)
    }

    @Test("Yield Mode enabled, being switched or cached as enabled maps to active")
    func mapsEffectivelyActiveStates() {
        #expect(yieldState(.active(info: .stub, promoStatus: .undefined)) == .active)
        #expect(yieldState(.processing(action: .enter)) == .active)
        #expect(yieldState(.processing(action: .exit)) == .active)
        #expect(yieldState(.loading(cachedState: .active(info: .stub, promoStatus: .undefined))) == .active)
        #expect(yieldState(.failedToLoad(error: "", cachedState: .active(info: .stub, promoStatus: .undefined))) == .active)
    }

    @Test("Disabled waits for the catalog while the manager has no market, and is final once it has one")
    func mapsDisabledByMarket() {
        #expect(yieldState(.disabled, marketInfo: nil) == .awaitingMarkets)
        #expect(yieldState(.disabled) == .disabled)
    }

    private func yieldState(
        _ state: YieldModuleManagerState,
        marketInfo: YieldModuleMarketInfo? = Self.marketInfo
    ) -> YieldModePromoPosition.YieldState {
        YieldModePromoPosition.YieldState(YieldModuleManagerStateInfo(marketInfo: marketInfo, state: state))
    }

    private static let marketInfo = YieldModuleMarketInfo(
        tokenContractAddress: "0xaaa",
        apy: 0.05,
        isActive: true,
        chainId: 1,
        maxFeeNative: nil,
        maxFeeUSD: nil,
        incentive: nil
    )
}

private extension YieldSupplyInfo {
    static let stub = YieldSupplyInfo(
        yieldContractAddress: "",
        balance: Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18),
        isAllowancePermissionRequired: false,
        yieldModuleBalanceValue: 0
    )
}
