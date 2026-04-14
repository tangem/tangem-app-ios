//
//  SwapState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

/// Single source of truth for one swap session.
/// Published from SwapModel via a single CurrentValueSubject<SwapState, Never>.
struct SwapState {
    // MARK: - Token pair

    var sourceToken: LoadingResult<SendSwapableToken, any Error>
    var receiveToken: LoadingResult<SendReceiveToken, any Error>

    // MARK: - User intent

    /// The amount the user explicitly typed.
    /// `.source(amount)` means user typed a source amount (float/from direction).
    /// `.receive(amount)` means user typed a receive amount (fixed/to direction).
    var userAmount: AmountDirection?

    /// The complementary amount computed from the quote.
    /// When userAmount is .source, this holds the estimated receive amount.
    /// When userAmount is .receive, this holds the required source amount.
    var complementaryAmount: SendAmount?

    // MARK: - Provider state

    var providers: ProvidersSnapshot

    // MARK: - Operational phase

    var phase: SwapPhase

    // MARK: - Transaction submission

    var isSending: Bool
}

// MARK: - Projections

extension SwapState {
    /// The effective source amount: either the user-typed source amount,
    /// or the computed source amount from a fixed-rate quote.
    var effectiveSourceAmount: SendAmount? {
        switch userAmount {
        case .source(let amount): amount
        case .receive: complementaryAmount
        case .none: nil
        }
    }

    /// The effective receive amount: either the computed receive amount from
    /// a float-rate quote, or the user-typed receive amount.
    var effectiveReceiveAmount: SendAmount? {
        switch userAmount {
        case .source: complementaryAmount
        case .receive(let amount): amount
        case .none: nil
        }
    }

    /// Rate type derived from amount direction. No separate tracking needed.
    var currentRateType: ExpressProviderRateType? {
        userAmount?.rateType
    }

    /// Whether we are in a loading state that should show loading UI for amounts
    var isLoadingRates: Bool {
        if case .loading(.rates) = phase { return true }
        return false
    }
}

// MARK: - AmountDirection

/// Unifies amount direction and rate type into one concept.
/// Eliminates the need for separate `_currentRateType` tracking.
enum AmountDirection: Equatable {
    /// User typed a source amount -> implies float rate type
    case source(SendAmount)
    /// User typed a receive amount -> implies fixed rate type
    case receive(SendAmount)

    var rateType: ExpressProviderRateType {
        switch self {
        case .source: .float
        case .receive: .fixed
        }
    }

    /// Convert to ExpressAmountType for the Express layer
    var expressAmountType: ExpressAmountType? {
        switch self {
        case .source(let amount): amount.crypto.map { .from($0) }
        case .receive(let amount): amount.crypto.map { .to($0) }
        }
    }

    var amount: SendAmount {
        switch self {
        case .source(let amount), .receive(let amount): amount
        }
    }
}

// MARK: - ProvidersSnapshot

/// Snapshot of provider state. Replaces the providers/selected
/// fields that were baked into ProvidersState.loaded enum case.
struct ProvidersSnapshot {
    var available: [ExpressAvailableProvider]
    var selected: ExpressAvailableProvider?

    static let empty = ProvidersSnapshot(available: [], selected: nil)
}

// MARK: - SwapPhase

/// The operational phase of the swap. Replaces the nested
/// ProvidersState + LoadedState enums with a flattened structure.
enum SwapPhase {
    case idle
    case loading(SwapLoadingType)
    case error(SwapPhaseError)
    case loaded(SwapLoadedPhase)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Accepted `loading types` to show some loading UI.
    /// Other `loading types` will be filtered.
    func filter(loading types: [SwapLoadingType]) -> Bool {
        switch self {
        case .loading(let type): types.contains(type)
        default: true
        }
    }
}

// MARK: - SwapLoadingType

enum SwapLoadingType: Equatable {
    case providers
    case provider
    case rates
    case autoupdate
    case fee
}

// MARK: - SwapPhaseError

struct SwapPhaseError: Equatable {
    let underlyingError: any Error
    let quote: SwapModel.Quote?

    static func == (lhs: SwapPhaseError, rhs: SwapPhaseError) -> Bool {
        lhs.underlyingError.localizedDescription == rhs.underlyingError.localizedDescription
            && lhs.quote == rhs.quote
    }
}

// MARK: - SwapLoadedPhase

/// Flattened loaded phase. Replaces LoadedState nested inside ProvidersState.loaded.
/// Each case carries exactly the data needed for that phase.
enum SwapLoadedPhase: Equatable {
    case idle
    case requiredRefresh(occurredError: any Error, quote: SwapModel.Quote?)
    case restriction(SwapModel.RestrictionType, quote: SwapModel.Quote?)
    case permissionRequired(SwapModel.PermissionRequiredState)
    case previewCEX(SwapModel.PreviewCEXState)
    case readyToSwap(SwapModel.ReadyToSwapState)

    var quote: SwapModel.Quote? {
        switch self {
        case .idle: nil
        case .requiredRefresh(_, let quote): quote
        case .restriction(_, let quote): quote
        case .permissionRequired(let state): state.quote
        case .previewCEX(let state): state.quote
        case .readyToSwap(let state): state.quote
        }
    }

    static func == (lhs: SwapLoadedPhase, rhs: SwapLoadedPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.requiredRefresh(_, let lq), .requiredRefresh(_, let rq)):
            return lq == rq
        case (.restriction(let lt, let lq), .restriction(let rt, let rq)):
            return "\(lt)" == "\(rt)" && lq == rq
        case (.permissionRequired(let l), .permissionRequired(let r)):
            return l.quote == r.quote
        case (.previewCEX(let l), .previewCEX(let r)):
            return l.quote == r.quote
        case (.readyToSwap(let l), .readyToSwap(let r)):
            return l.quote == r.quote
        default:
            return false
        }
    }
}

// MARK: - SwapPhase + CustomStringConvertible

extension SwapPhase: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle: "idle"
        case .loading(let type): "loading(\(type))"
        case .error(let error): "error(\(error.underlyingError.localizedDescription))"
        case .loaded(let phase): "loaded(\(phase))"
        }
    }
}

// MARK: - SwapLoadedPhase + CustomStringConvertible

extension SwapLoadedPhase: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle: "idle"
        case .requiredRefresh(let error, _): "requiredRefresh(\(error))"
        case .restriction(let restriction, _): "restriction(\(restriction))"
        case .permissionRequired: "permissionRequired"
        case .previewCEX: "previewCEX"
        case .readyToSwap: "readyToSwap"
        }
    }
}

// MARK: - SwapLoadingType + analyticsScreenName

extension SwapLoadingType {
    var analyticsScreenName: Analytics.ParameterValue {
        switch self {
        case .rates, .providers, .provider:
            return .amount
        case .autoupdate, .fee:
            return .confirmation
        }
    }
}
