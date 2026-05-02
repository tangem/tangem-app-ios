//
//  SwapState+Transitions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

/// Named mutating transitions on `SwapState`. Each method names a single state
/// change so the model can express intent without inlining field-level mutation
/// logic. Use via `_state.mutate { $0.X(...) }` — the closure-based atomic
/// mutator in `CurrentValueSubject<SwapState, Never>` ensures a single Combine
/// emission per call.
extension SwapState {
    // MARK: - User input

    /// Anchor on the source direction with the given amount (or clear).
    /// Called both when the user types a source amount and when the user taps
    /// the compact source field to switch direction with the existing value.
    /// On direction flip (was `.receive`), promote the previous receive amount
    /// into `complementaryAmount` so it carries the correct token's units —
    /// otherwise the stale complementary belongs to the wrong side and would
    /// be reinterpreted as the new direction's complement, causing a brief
    /// flash of the wrong amount before the next quote completes. Token-change
    /// flows that promote `complementaryAmount` into `userAmount` also depend
    /// on this invariant.
    mutating func setSourceDirection(amount: SendAmount?) {
        if case .receive(let oldReceive) = userAmount {
            complementaryAmount = oldReceive
        }
        userAmount = amount.map { .source($0) }
        if amount == nil {
            complementaryAmount = nil
        }
    }

    /// Anchor on the receive direction with the given amount (or clear).
    /// See `setSourceDirection` for the direction-flip rationale.
    mutating func setReceiveDirection(amount: SendAmount?) {
        if case .source(let oldSource) = userAmount {
            complementaryAmount = oldSource
        }
        userAmount = amount.map { .receive($0) }
        if amount == nil {
            complementaryAmount = nil
        }
    }

    // MARK: - Token selection

    mutating func setSourceToken(_ wallet: SendSwapableToken) {
        sourceToken = .success(wallet)
    }

    /// Apply a receive-token selection. On token change, wipe stale receive-side
    /// amount state so the publisher doesn't emit a `.success` carrying the old
    /// token's value during the loading window — that would cause the view's
    /// `pendingReverseRecalculation` to fire `interactor.update(receiveAmount:)`
    /// with the wrong value and cancel the in-flight pair-change task.
    /// When `userAmount` was `.receive`, promote `complementaryAmount` (the
    /// source value, in source token's units) into `userAmount = .source(...)`
    /// so the receive-token-changed handler still has a sourceAmount to work with.
    mutating func setReceiveToken(_ wallet: SendReceiveToken) {
        let tokenChanged = receiveToken.value?.tokenItem.id != wallet.tokenItem.id
        if tokenChanged {
            if case .receive = userAmount, let source = complementaryAmount {
                userAmount = .source(source)
            }
            complementaryAmount = nil
        }
        receiveToken = .success(wallet)
    }

    mutating func markSourceTokenLoading() {
        sourceToken = .loading
    }

    mutating func markReceiveTokenLoading() {
        receiveToken = .loading
    }

    mutating func markSourceTokenRequiresSelection() {
        sourceToken = .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    mutating func markReceiveTokenRequiresSelection() {
        receiveToken = .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    mutating func markBothTokensRequireSelection() {
        markSourceTokenRequiresSelection()
        markReceiveTokenRequiresSelection()
    }

    mutating func failSourceTokenLoading(_ error: any Error) {
        sourceToken = .failure(error)
    }

    mutating func failReceiveTokenLoading(_ error: any Error) {
        receiveToken = .failure(error)
    }

    /// Fail every token that's currently in `.loading` state. Used when initial
    /// pair loading fails after one of the tokens has started loading.
    mutating func failPendingTokenLoads(_ error: any Error) {
        if receiveToken.isLoading {
            receiveToken = .failure(error)
        }
        if sourceToken.isLoading {
            sourceToken = .failure(error)
        }
    }

    /// Mark both tokens as not-found — used when initial loading lands in an
    /// unexpected default state.
    mutating func failTokenLookup() {
        sourceToken = .failure(SwapModel.SwapModelError.sourceNotFound)
        receiveToken = .failure(SwapModel.SwapModelError.destinationNotFound)
    }

    // MARK: - Token swap

    /// Direct swap of source and receive — V1 path where both are valid.
    mutating func swapSourceAndReceive(newSource: SendSwapableToken, newReceive: SendReceiveToken) {
        sourceToken = .success(newSource)
        receiveToken = .success(newReceive)
    }

    /// Move the given token into the receive slot and mark source as requiring
    /// selection — V2 path when destination is not swap-capable, or when only
    /// the source side was set previously.
    mutating func setReceiveTokenAndRequireSourceSelection(_ token: SendReceiveToken) {
        receiveToken = .success(token)
        sourceToken = .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    /// Promote the previous destination into the source slot if it's
    /// swap-capable, otherwise leave source as requiring selection. Receive
    /// becomes requires-selection in either case — V2 path.
    mutating func promoteDestinationToSourceAndRequireReceiveSelection(_ destination: SendReceiveToken) {
        if let swapableDestination = destination as? SendSwapableToken {
            sourceToken = .success(swapableDestination)
        } else {
            sourceToken = .failure(SwapModel.SwapModelError.tokenSelectionRequired)
        }
        receiveToken = .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    // MARK: - Loading lifecycle

    mutating func setPhase(_ phase: SwapPhase) {
        self.phase = phase
    }

    mutating func setIdleNoProviders() {
        providers = .empty
        phase = .idle
    }

    mutating func setLoaded(providers snapshot: ProvidersSnapshot, phase loadedPhase: SwapLoadedPhase) {
        providers = snapshot
        phase = .loaded(loadedPhase)
    }

    mutating func setLoadingError(_ error: any Error) {
        providers = .empty
        phase = .error(SwapPhaseError(underlyingError: error, quote: nil))
    }

    mutating func markPendingApproveTransaction(quote: SwapModel.Quote) {
        phase = .loaded(.restriction(.hasPendingApproveTransaction, quote: quote))
    }

    // MARK: - Amount results

    mutating func setComplementaryAmount(_ amount: SendAmount?) {
        complementaryAmount = amount
    }

    /// Float-rate quote result: source side anchors the next quote, receive
    /// side is the server-computed complement.
    mutating func anchorOnSource(_ source: SendAmount, complementary: SendAmount) {
        userAmount = .source(source)
        complementaryAmount = complementary
    }

    /// Fixed-rate quote result: receive side anchors the next quote, source
    /// side is the server-refined complement.
    mutating func anchorOnReceive(_ receive: SendAmount, complementary: SendAmount) {
        userAmount = .receive(receive)
        complementaryAmount = complementary
    }

    /// User cleared the receive token. Receive enters the loading state and
    /// the complementary amount is dropped.
    mutating func clearReceiveTokenSelection() {
        complementaryAmount = nil
        receiveToken = .loading
    }

    // MARK: - Sending

    mutating func setIsSending(_ flag: Bool) {
        isSending = flag
    }
}
