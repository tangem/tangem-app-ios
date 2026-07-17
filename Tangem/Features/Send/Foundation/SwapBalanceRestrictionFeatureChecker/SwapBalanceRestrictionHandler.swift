//
//  SwapBalanceRestrictionHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

/// Applies the total-balance restriction to the swap flow: hides providers entirely (legacy)
/// or narrows them to DEX-only for an unfunded hot wallet.
final class SwapBalanceRestrictionHandler {
    private let checker: SwapBalanceRestrictionFeatureChecker
    private let _isDexOnlyProvidersMode = CurrentValueSubject<Bool, Never>(false)

    init(checker: SwapBalanceRestrictionFeatureChecker) {
        self.checker = checker
    }

    var isDexOnlyProvidersMode: Bool {
        _isDexOnlyProvidersMode.value
    }

    /// Resolves the restriction and refreshes the DEX-only mode.
    /// `true` means the legacy behavior: no sign of providers in the UI.
    func shouldHideProviders(for token: SendSourceToken) async throws -> Bool {
        switch try await checker.swapTotalBalanceRestriction(for: token) {
        case .none:
            _isDexOnlyProvidersMode.send(false)
            return false

        case .hideProviders:
            _isDexOnlyProvidersMode.send(false)
            return true

        case .dexProvidersOnly:
            // Quotes still load; the state is narrowed in `dexOnlyAdjustedState`
            _isDexOnlyProvidersMode.send(true)
            return false
        }
    }

    /// Narrows the state to DEX providers while the wallet is unfunded. The engine prefers an
    /// eligible DEX, so a non-DEX selection means the pair has no usable DEX — `nil` requests
    /// the legacy fallback. Best flags are recomputed so the best visible DEX gets the regular
    /// "Best rate" badge.
    func dexOnlyAdjustedState(_ state: ExpressManagerState) -> ExpressManagerState? {
        guard _isDexOnlyProvidersMode.value else {
            return state
        }

        switch state {
        case .idle:
            return state

        case .transfer:
            // A transfer of the same currency cannot be funded from a zero balance
            return nil

        case .swap(let selected, let providers):
            if let selected, !selected.provider.type.isDEX {
                return nil
            }

            let dexProviders = providers.filter(\.provider.type.isDEX)

            for rateType in [ExpressProviderRateType.float, .fixed] {
                dexProviders.availableProviders(rate: rateType).updateIsBestFlagPreferringDEX()
            }

            return .swap(selected: selected, providers: dexProviders)
        }
    }
}
