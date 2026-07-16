//
//  SwapBalanceRestrictionHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

/// Applies the total-balance restriction to the swap providers flow: decides whether providers
/// are hidden entirely (legacy behavior) and drives the [REDACTED_INFO] DEX-only mode, where quotes
/// are loaded for an unfunded hot wallet but only DEX providers are exposed to the UI.
final class SwapBalanceRestrictionHandler {
    private let checker: SwapBalanceRestrictionFeatureChecker
    private let _isDexOnlyProvidersMode = CurrentValueSubject<Bool, Never>(false)

    init(checker: SwapBalanceRestrictionFeatureChecker) {
        self.checker = checker
    }

    var isDexOnlyProvidersMode: Bool {
        _isDexOnlyProvidersMode.value
    }

    /// Resolves the restriction for the token and refreshes the DEX-only mode.
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
            // Let the pipeline run so quotes are loaded; the state is
            // narrowed to DEX providers in `dexOnlyAdjustedState`.
            _isDexOnlyProvidersMode.send(true)
            return false
        }
    }

    /// [REDACTED_INFO]: while the wallet is unfunded the state is narrowed to DEX providers, so every
    /// downstream consumer sees a consistent DEX-only world. The engine prefers an eligible DEX
    /// on selection, so a non-DEX selection means the pair has no usable DEX — `nil` falls back
    /// to the legacy error-only behavior. Best flags are recomputed over the visible providers,
    /// so the best DEX carries the regular "Best rate" badge instead of "Best DEX rate".
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

            if let selected {
                dexProviders.availableProviders(rate: selected.rateType).updateIsBestFlagPreferringDEX()
            }

            return .swap(selected: selected, providers: dexProviders)
        }
    }
}
