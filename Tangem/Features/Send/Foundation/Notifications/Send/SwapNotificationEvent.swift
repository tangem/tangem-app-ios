//
//  SwapNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemExpress
import TangemAssets

enum SwapNotificationEvent: Hashable {
    // Express specific notifications
    case permissionNeeded(providerName: String, currencyCode: String, analyticsParams: [Analytics.ParameterKey: String])
    case refreshRequired(
        title: String,
        message: String,
        expressErrorCode: ExpressAPIError.Code? = nil,
        analyticsParams: [Analytics.ParameterKey: String]? = nil
    )
    case hasPendingTransaction(symbol: String)
    case hasPendingApproveTransaction
    case notEnoughFeeForTokenTx(mainTokenName: String, mainTokenSymbol: String, blockchainIconAsset: ImageType, analyticsParams: [Analytics.ParameterKey: String])
    case tooSmallAmountToSwap(minimumAmountText: String)
    case tooBigAmountToSwap(maximumAmountText: String)
    case unsupportedPair(analyticsParams: [Analytics.ParameterKey: String])
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case notEnoughReceivedAmountForReserve(amountFormatted: String)

    /// The destination (receive) wallet is card-linked and must not be topped up.
    /// Mirrors the main-screen backup-error notification.
    case incompleteBackup

    // Generic notifications is received from BSDK
    case withdrawalNotificationEvent(WithdrawalNotificationEvent)
    case validationErrorEvent(event: ValidationErrorEvent)

    // The notifications which is used only on the PendingExpressTxStatusBottomSheetView
    case verificationRequired
    case cexOperationFailed

    case refunded(tokenItem: TokenItem)

    case notEnoughBalanceForSwapping(analyticsParams: [Analytics.ParameterKey: String])

    /// If the client's transaction takes longer than the average time by x5 times
    case longTimeAverageDuration

    /// High price impact warning/block banner
    case highPriceImpactWarning(level: HighPriceImpactCalculator.Level, analyticsParams: [Analytics.ParameterKey: String])
}

extension SwapNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .permissionNeeded:
            return .string(Localization.expressProviderPermissionNeededV2)
        case .refreshRequired(let title, _, _, _):
            return .string(title)
        case .hasPendingTransaction:
            return .string(Localization.warningExpressActiveTransactionTitle)
        case .hasPendingApproveTransaction:
            return .string(Localization.warningExpressApprovalInProgressTitle)
        case .notEnoughFeeForTokenTx(let mainTokenName, _, _, _):
            return .string(Localization.warningExpressNotEnoughFeeForTokenTxTitle(mainTokenName))
        case .tooSmallAmountToSwap(let minimumAmountText):
            return .string(Localization.warningExpressTooMinimalAmountTitle(minimumAmountText))
        case .tooBigAmountToSwap(let maximumAmountText):
            return .string(Localization.warningExpressTooMaximumAmountTitle(maximumAmountText))
        case .unsupportedPair:
            return .string(Localization.warningExpressUnsupportedPairTitle)
        case .verificationRequired:
            return .string(Localization.expressExchangeNotificationVerificationTitle)
        case .cexOperationFailed:
            return .string(Localization.expressExchangeNotificationFailedTitle)
        case .feeWillBeSubtractFromSendingAmount:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .notEnoughReceivedAmountForReserve(let amountFormatted):
            return .string(Localization.warningExpressNotificationInvalidReserveAmountTitle(amountFormatted))
        case .incompleteBackup:
            return .string(Localization.onboardingActivationErrorTitle)
        case .withdrawalNotificationEvent(let event):
            return event.title
        case .validationErrorEvent(let event):
            return event.title
        case .refunded(tokenItem: let tokenItem):
            return .string(Localization.expressExchangeNotificationRefundTitle(tokenItem.currencySymbol, tokenItem.networkName))
        case .notEnoughBalanceForSwapping:
            return .string(Localization.swappingInsufficientFunds)
        case .longTimeAverageDuration:
            return .string(Localization.expressExchangeNotificationLongTransactionTimeTitle)
        case .highPriceImpactWarning(.negligible, _):
            return nil // Filtered out in SwapNotificationManager, kept for exhaustiveness
        case .highPriceImpactWarning(.warningLoss, _):
            return .string(Localization.swappingHighPriceImpactTitle)
        case .highPriceImpactWarning(.highLossLowAmount, _), .highPriceImpactWarning(.highLossHighAmount, _):
            return .string(Localization.swappingTradeTooLargeTitle)
        }
    }

    var description: String? {
        switch self {
        case .permissionNeeded:
            let learnMore = TangemHelpCenterUrlBuilder()
                .url(article: .howToSwapCoinsAndTokens)
                .map { "[\(Localization.commonLearnMore)](\($0.absoluteString))" }
                ?? Localization.commonLearnMore
            return Localization.givePermissionSwapSubtitleV2(learnMore)
        case .refreshRequired(_, let message, _, _):
            return message
        case .hasPendingTransaction(let symbol):
            return Localization.warningExpressActiveTransactionMessage(symbol)
        case .hasPendingApproveTransaction:
            return Localization.warningExpressApprovalInProgressMessage
        case .notEnoughFeeForTokenTx(let mainTokenName, let mainTokenSymbol, _, _):
            return Localization.warningExpressNotEnoughFeeForTokenTxDescription(mainTokenName, mainTokenSymbol)
        case .tooSmallAmountToSwap, .tooBigAmountToSwap:
            return Localization.warningExpressWrongAmountDescription
        case .notEnoughReceivedAmountForReserve:
            return Localization.sendNotificationInvalidReserveAmountText
        case .incompleteBackup:
            return Localization.warningBackupErrorsMessage
        case .unsupportedPair:
            return Localization.warningExpressUnsupportedPairDescription
        case .verificationRequired:
            return Localization.expressExchangeNotificationVerificationText
        case .cexOperationFailed:
            return Localization.expressExchangeNotificationFailedText
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            return Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        // Only for dustRestriction we have to use different description
        case .validationErrorEvent(.dustRestriction(let minimumAmountFormatted, let minimumChangeFormatted)):
            return Localization.warningExpressDustMessage(minimumAmountFormatted, minimumChangeFormatted)
        case .withdrawalNotificationEvent(let event):
            return event.description
        case .validationErrorEvent(let event):
            return event.description
        case .refunded(tokenItem: let tokenItem):
            let url = TangemBlogUrlBuilder().url(post: .refundedDex)
            let readMore = "[\(Localization.commonReadMore)](\(url.absoluteString))"
            return Localization.expressExchangeNotificationRefundText(tokenItem.currencySymbol, readMore)
        case .notEnoughBalanceForSwapping:
            return Localization.swappingInsufficientFundsDescription
        case .longTimeAverageDuration:
            return Localization.expressExchangeNotificationLongTransactionTimeText
        case .highPriceImpactWarning(.negligible, _):
            return nil // Filtered out in SwapNotificationManager, kept for exhaustiveness
        case .highPriceImpactWarning(.warningLoss, _):
            return Localization.swappingHighPriceImpactText
        case .highPriceImpactWarning(.highLossLowAmount, _), .highPriceImpactWarning(.highLossHighAmount, _):
            return Localization.swappingTradeTooLargeText
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .unsupportedPair,
             .feeWillBeSubtractFromSendingAmount,
             .notEnoughBalanceForSwapping,
             .highPriceImpactWarning(.negligible, _), // Filtered out in SwapNotificationManager, kept for exhaustiveness
             .highPriceImpactWarning(.warningLoss, _):
            return .secondary
        case .highPriceImpactWarning(.highLossLowAmount, _), .highPriceImpactWarning(.highLossHighAmount, _):
            return .action
        case .notEnoughFeeForTokenTx,
             .refreshRequired,
             .verificationRequired,
             .cexOperationFailed,
             .notEnoughReceivedAmountForReserve,
             .refunded,
             .longTimeAverageDuration,
             .permissionNeeded:
            return .action
        case .withdrawalNotificationEvent(let event):
            return event.colorScheme
        case .validationErrorEvent(let event):
            return event.colorScheme
        case .incompleteBackup:
            return .critical
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .permissionNeeded:
            return .init(iconType: .image(Assets.swapLock))
        case .refreshRequired,
             .unsupportedPair,
             .verificationRequired,
             .feeWillBeSubtractFromSendingAmount,
             .longTimeAverageDuration,
             .highPriceImpactWarning(.negligible, _), // Filtered out in SwapNotificationManager, kept for exhaustiveness
             .highPriceImpactWarning(.warningLoss, _):
            return .init(iconType: .image(Assets.attention))
        case .highPriceImpactWarning(.highLossLowAmount, _), .highPriceImpactWarning(.highLossHighAmount, _):
            return .init(iconType: .image(Assets.redCircleWarning))
        case .hasPendingApproveTransaction,
             .hasPendingTransaction:
            return .init(iconType: .progressView)
        case .notEnoughFeeForTokenTx(_, _, let blockchainIconAsset, _):
            return .init(iconType: .image(blockchainIconAsset))
        case .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .cexOperationFailed,
             .notEnoughReceivedAmountForReserve,
             .notEnoughBalanceForSwapping:
            return .init(iconType: .image(Assets.redCircleWarning))
        case .incompleteBackup:
            return .init(
                iconType: .image(Assets.DesignSystem.attention),
                renderingMode: .template,
                color: .Tangem.Text.Neutral.primary,
                size: .init(bothDimensions: 28)
            )
        case .withdrawalNotificationEvent(let event):
            return event.icon
        case .validationErrorEvent(let event):
            return event.icon
        case .refunded(let tokenItem):
            let iconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
            return .init(iconType: .icon(iconInfo), size: CGSize(bothDimensions: 36))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .permissionNeeded,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .verificationRequired,
             .feeWillBeSubtractFromSendingAmount,
             .refunded,
             .longTimeAverageDuration:
            return .info
        case .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .unsupportedPair,
             .notEnoughReceivedAmountForReserve,
             .notEnoughBalanceForSwapping,
             .highPriceImpactWarning(.negligible, _), // Filtered out in SwapNotificationManager, kept for exhaustiveness
             .highPriceImpactWarning(.warningLoss, _):
            return .warning
        case .highPriceImpactWarning(.highLossLowAmount, _),
             .highPriceImpactWarning(.highLossHighAmount, _):
            return .critical
        case .refreshRequired,
             .cexOperationFailed,
             .incompleteBackup:
            return .critical
        case .withdrawalNotificationEvent(let event):
            return event.severity
        case .validationErrorEvent(let event):
            return event.severity
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .notEnoughFeeForTokenTx(_, let mainTokenSymbol, _, _):
            return .init(.openFeeCurrency(currencySymbol: mainTokenSymbol))
        case .refreshRequired:
            return .init(.refresh, withLoader: true)
        case .verificationRequired, .cexOperationFailed, .longTimeAverageDuration:
            return .init(.goToProvider)
        case .validationErrorEvent(let event):
            return event.buttonAction
        case .withdrawalNotificationEvent(let event):
            return event.buttonAction
        case .refunded:
            return .init(.openCurrency)
        case .permissionNeeded:
            return .init(.givePermission)
        case .incompleteBackup:
            return .init(.backupErrorSupport)
        default:
            return nil
        }
    }

    var descriptionLinkTint: Color? {
        switch self {
        case .permissionNeeded:
            return Colors.Text.accent
        default:
            return nil
        }
    }

    var removingOnFullLoadingState: Bool {
        switch self {
        case .unsupportedPair, .refreshRequired, .verificationRequired, .cexOperationFailed, .refunded, .longTimeAverageDuration, .incompleteBackup:
            return false
        case .permissionNeeded,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .feeWillBeSubtractFromSendingAmount,
             .notEnoughReceivedAmountForReserve,
             .notEnoughBalanceForSwapping,
             .withdrawalNotificationEvent,
             .validationErrorEvent,
             .highPriceImpactWarning:
            return true
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Analytics

extension SwapNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .refreshRequired(_, _, .exchangeNotPossibleError, _):
            .swapNoticeExpressError
        case .permissionNeeded:
            .swapNoticePermissionNeeded
        case .highPriceImpactWarning(.warningLoss, _):
            .swapNoticeHighPriceImpact
        case .highPriceImpactWarning(.highLossLowAmount, _), .highPriceImpactWarning(.highLossHighAmount, _):
            .swapNoticeTradeTooLarge
        case .notEnoughFeeForTokenTx:
            .swapNoticeNotEnoughFee
        case .notEnoughBalanceForSwapping:
            .swapNoticeNotEnoughFunds
        case .unsupportedPair:
            .swapNoticeUnavailableToSwapPair
        case .longTimeAverageDuration:
            // Sending from in place PendingExpressTxStatusBottomSheetViewModel.swift
            nil
        default:
            nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .refreshRequired(_, _, _, .some(let params)):
            params
        case .permissionNeeded(_, _, let params):
            params
        case .highPriceImpactWarning(_, let params):
            params
        case .unsupportedPair(let params):
            params
        case .notEnoughFeeForTokenTx(_, _, _, let params):
            params
        case .notEnoughBalanceForSwapping(let params):
            params
        default:
            [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        switch self {
        case .permissionNeeded:
            return true
        default:
            return false
        }
    }
}
