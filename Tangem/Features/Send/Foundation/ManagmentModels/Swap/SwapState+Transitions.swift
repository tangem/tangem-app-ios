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

    /// User typed a source amount (or cleared it). Direction becomes `.source`.
    /// When amount is `nil`, the complementary amount is also cleared.
    mutating func userTypedSourceAmount(_ amount: SendAmount?) {
        userAmount = amount.map { .source($0) }
        if amount == nil {
            complementaryAmount = nil
        }
    }

    /// User typed a receive amount (or cleared it). Direction becomes `.receive`.
    /// When amount is `nil`, the complementary amount is also cleared.
    mutating func userTypedReceiveAmount(_ amount: SendAmount?) {
        userAmount = amount.map { .receive($0) }
        if amount == nil {
            complementaryAmount = nil
        }
    }

    // MARK: - Token selection

    mutating func setSourceToken(_ wallet: SendSwapableToken) {
        sourceToken = .success(wallet)
    }

    /// Apply a receive-token selection. If the token actually changed, the
    /// receive-side amount is cleared; if the user had typed a receive amount,
    /// that direction is dropped so the next quote can re-anchor.
    mutating func setReceiveToken(_ wallet: SendReceiveToken) {
        let tokenChanged = receiveToken.value?.tokenItem.id != wallet.tokenItem.id
        if tokenChanged {
            complementaryAmount = nil
            if case .receive = userAmount {
                userAmount = nil
            }
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
