//
//  SwapBalanceRestrictionHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

/// Applies the total-balance restriction to the swap flow: hides providers entirely (legacy)
/// or narrows them to DEX-only for an unfunded hot wallet.
final class SwapBalanceRestrictionHandler {
    private let checker: SwapBalanceRestrictionFeatureChecker
    /// Written across a non-isolated async hop and read from the main actor, so it needs a lock
    private let _isDexOnlyProvidersMode = OSAllocatedUnfairLock(initialState: false)

    init(checker: SwapBalanceRestrictionFeatureChecker) {
        self.checker = checker
    }

    var isDexOnlyProvidersMode: Bool {
        _isDexOnlyProvidersMode.withLock { $0 }
    }

    /// Resolves the restriction and refreshes the DEX-only mode.
    /// `true` means the legacy behavior: no sign of providers in the UI.
    func shouldHideProviders(for token: SendSourceToken) async throws -> Bool {
        switch try await checker.swapTotalBalanceRestriction(for: token) {
        case .none:
            setDexOnlyProvidersMode(false)
            return false

        case .hideProviders:
            setDexOnlyProvidersMode(false)
            return true

        case .dexProvidersOnly:
            // Quotes still load; the state is narrowed in `dexOnlyAdjustedState`
            setDexOnlyProvidersMode(true)
            return false
        }
    }

    private func setDexOnlyProvidersMode(_ enabled: Bool) {
        _isDexOnlyProvidersMode.withLock { $0 = enabled }
    }

    /// Narrows the state to DEX providers while the wallet is unfunded. The engine prefers an
    /// eligible DEX, so a non-DEX selection means the pair has no usable DEX — `nil` requests
    /// the legacy fallback. Best flags are recomputed so the best visible DEX gets the regular
    /// "Best rate" badge.
    func dexOnlyAdjustedState(_ state: ExpressManagerState) -> ExpressManagerState? {
        guard isDexOnlyProvidersMode else {
            return state
        }

        switch state {
        case .idle:
            return state

        case .transfer:
            // A transfer of the same currency cannot be funded from a zero balance
            return nil

        case .swap(let selected, let providers):
            guard let selected, selected.provider.type.isDEX else {
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
