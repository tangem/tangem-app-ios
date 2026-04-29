//
//  SwapPhaseMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// Pure mapper from `ExpressManagerUpdatingResult` into `SwapLoadedPhase`.
/// Holds no mutable state — instantiate per call with the current source/receive snapshot.
struct SwapPhaseMapper {
    let sourceToken: LoadingResult<SendSwapableToken, any Error>
    let receiveToken: LoadingResult<SendReceiveToken, any Error>

    func mapToLoadedPhase(result: ExpressManagerUpdatingResult) async throws -> SwapLoadedPhase {
        guard let selected = result.selected else {
            return .idle
        }

        switch selected.getState() {
        case .idle:
            return .idle

        case .error(_, let quote) where hasPendingTransaction():
            guard let quote else {
                return .restriction(.hasPendingTransaction, quote: .none)
            }

            let mappedQuote = try await map(provider: selected.provider, quote: quote)
            return .restriction(.hasPendingTransaction, quote: mappedQuote)

        case .error(let error, .none):
            return .requiredRefresh(occurredError: error, quote: .none)

        case .error(let error, .some(let quote)):
            let quote = try await map(provider: selected.provider, quote: quote)
            return .requiredRefresh(occurredError: error, quote: quote)

        case .restriction(let restriction, .none):
            return .restriction(map(restriction: restriction), quote: .none)

        case .restriction(let restriction, .some(let quote)):
            let quote = try await map(provider: selected.provider, quote: quote)
            return .restriction(map(restriction: restriction), quote: quote)

        case .permissionRequired(let permissionRequired) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: permissionRequired.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .cexPreview(let previewCEX) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: previewCEX.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .dexPreview(let dexPreview) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: dexPreview.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .permissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)

        case .cexPreview(let previewCEX):
            return try await map(provider: selected, previewCEX: previewCEX)

        case .dexPreview(let dexPreview):
            return try await map(provider: selected, dexPreview: dexPreview)

        case .revokeAndPermissionRequired(let permissionRequired) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: permissionRequired.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .revokeAndPermissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)
        }
    }

    func map(provider: ExpressProvider, quote: ExpressQuote) async throws -> SwapModel.Quote {
        let highPriceImpact = try await calculateHighPriceImpact(provider: provider, quote: quote)
        return SwapModel.Quote(fromAmount: quote.fromAmount, expectAmount: quote.expectAmount, highPriceImpact: highPriceImpact)
    }

    func calculateHighPriceImpact(provider: ExpressProvider, quote: ExpressQuote?) async throws -> HighPriceImpactCalculator.Result? {
        guard let quote,
              let source = sourceToken.value?.tokenItem,
              let destination = receiveToken.value?.tokenItem
        else {
            return nil
        }

        let input = HighPriceImpactCalculator.Input(
            provider: provider,
            sourceToken: source,
            destinationToken: destination,
            sourceAmount: quote.fromAmount,
            destinationAmount: quote.expectAmount
        )

        return try await HighPriceImpactCalculator().calculate(input: input)
    }

    func hasPendingTransaction() -> Bool {
        let sendingRestrictionsProvider = sourceToken.value?.sendingRestrictionsProvider
        let hasPendingTransaction = sendingRestrictionsProvider?.sendingRestrictions?.isHasPendingTransaction
        return hasPendingTransaction ?? false
    }

    func map(restriction: ExpressRestriction) -> SwapModel.RestrictionType {
        switch restriction {
        case .tooSmallAmount(let minAmount, let currencySymbol):
            return .tooSmallAmountForSwapping(minAmount: minAmount, currencySymbol: currencySymbol)

        case .tooBigAmount(let maxAmount, let currencySymbol):
            return .tooBigAmountForSwapping(maxAmount: maxAmount, currencySymbol: currencySymbol)

        case .approveTransactionInProgress:
            return .hasPendingApproveTransaction

        case .insufficientBalance(let requiredAmount):
            return .notEnoughBalanceForSwapping(requiredAmount: requiredAmount)

        case .feeCurrencyHasZeroBalance(let isFeeCurrency):
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)

        case .feeCurrencyInsufficientBalanceForTxValue(let fee, let isFeeCurrency):
            return .notEnoughAmountForTxValue(fee, isFeeCurrency: isFeeCurrency)
        }
    }

    func map(
        provider: ExpressAvailableProvider,
        permissionRequired: ExpressProviderManagerState.PermissionRequired
    ) async throws -> SwapLoadedPhase {
        let amount = makeAmount(value: permissionRequired.quote.fromAmount, tokenItem: try sourceToken.get().tokenItem)
        let fee = permissionRequired.fee
        let quote = try await map(provider: provider.provider, quote: permissionRequired.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let permissionRequiredState = SwapModel.PermissionRequiredState(
            quote: quote,
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            approvalFlow: permissionRequired.approvalFlow
        )

        return .permissionRequired(permissionRequiredState)
    }

    func map(provider: ExpressAvailableProvider, dexPreview: ExpressProviderManagerState.DEXPreview) async throws -> SwapLoadedPhase {
        let source = try sourceToken.get()
        let fee = dexPreview.fee

        let amount = makeAmount(value: dexPreview.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: dexPreview.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let readyToSwapState = SwapModel.ReadyToSwapState(quote: quote, data: dexPreview.data, fee: fee)
        return .readyToSwap(readyToSwapState)
    }

    func map(provider: ExpressAvailableProvider, previewCEX: ExpressProviderManagerState.CEXPreview) async throws -> SwapLoadedPhase {
        let source = try sourceToken.get()
        let fee = previewCEX.fee

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: previewCEX.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        if let memoRequiredRestriction = try validateMemoRequired() {
            return .restriction(memoRequiredRestriction, quote: quote)
        }

        let withdrawalNotificationProvider = source.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = receiveToken.value as? SendSwapableToken {
            let restriction = destination.receivingRestrictionsProvider.restriction(expectAmount: previewCEX.quote.expectAmount)
            switch restriction {
            case .none:
                break
            case .notEnoughReceivedAmount(let minAmount):
                return .restriction(
                    .notEnoughReceivedAmount(minAmount: minAmount, tokenSymbol: destination.tokenItem.currencySymbol),
                    quote: quote
                )
            }
        }

        let feeTokenItem = try provider.getTokenFeeProvidersManager().selectedFeeProvider.feeTokenItem
        let subtractFee = SwapModel.SubtractFee(feeTokenItem: feeTokenItem, subtractFee: previewCEX.subtractFee)

        let previewCEXState = SwapModel.PreviewCEXState(
            quote: quote,
            subtractFee: subtractFee,
            fee: fee,
            isExemptFee: source.isExemptFee,
            notification: notification
        )

        return .previewCEX(previewCEXState)
    }

    func validate(amount: Amount, fee: Fee) throws -> SwapModel.RestrictionType? {
        do {
            let source = try sourceToken.get()
            let transactionValidator = source.expressTransactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .notEnoughBalanceForSwapping(requiredAmount: amount.value)
        } catch ValidationError.feeExceedsBalance {
            let isFeeCurrency = fee.amount.type == amount.type
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)
        } catch let error as ValidationError {
            return .validationError(error: error)
        } catch {
            ExpressLogger.error(error: "Not expected error: \(error)")
            throw error
        }

        return nil
    }

    func validateMemoRequired() throws -> SwapModel.RestrictionType? {
        let receive = try receiveToken.get()

        let destination = receive.destination
        switch destination?.destination {
        case .resolved(_, _, memoRequired: true) where destination?.destinationTag == nil:
            return .validationError(error: .destinationMemoRequired)
        default:
            return nil
        }
    }

    func makeAmount(value: Decimal, tokenItem: TokenItem) -> BSDKAmount {
        Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }
}
