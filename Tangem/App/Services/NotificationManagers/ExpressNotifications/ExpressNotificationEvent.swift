//
//  ExpressNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ExpressNotificationEvent {
    case permissionNeeded(currencyCode: String)
    case refreshRequired(title: String, message: String)
    case hasPendingTransaction(symbol: String)
    case hasPendingApproveTransaction
    case notEnoughFeeForTokenTx(mainTokenName: String, mainTokenSymbol: String, blockchainIconName: String)
    case notEnoughAmountToSwap(minimumAmountText: String)
    case notEnoughBalanceToSwap(maximumAmountText: String)
    case noDestinationTokens(sourceTokenName: String)
    case highPriceImpact
    case verificationRequired
    case cexOperationFailed
    case feeWillBeSubtractFromSendingAmount(reducedAmount: String)
}

extension ExpressNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .permissionNeeded:
            return Localization.expressProviderPermissionNeeded
        case .refreshRequired(let title, _):
            return title
        case .hasPendingTransaction:
            return Localization.warningExpressActiveTransactionTitle
        case .hasPendingApproveTransaction:
            return Localization.warningExpressApprovalInProgressTitle
        case .notEnoughFeeForTokenTx(let mainTokenName, _, _):
            return Localization.warningExpressNotEnoughFeeForTokenTxTitle(mainTokenName)
        case .notEnoughAmountToSwap(let minimumAmountText):
            return Localization.warningExpressTooMinimalAmountTitle(minimumAmountText)
        case .notEnoughBalanceToSwap(let maximumAmountText):
            return Localization.sendNotificationInvalidReserveAmountTitle(maximumAmountText)
        case .noDestinationTokens:
            return Localization.warningExpressNoExchangeableCoinsTitle
        case .highPriceImpact:
            return Localization.swappingHighPriceImpact
        case .verificationRequired:
            return Localization.expressExchangeNotificationVerificationTitle
        case .cexOperationFailed:
            return Localization.expressExchangeNotificationFailedTitle
        case .feeWillBeSubtractFromSendingAmount:
            return Localization.sendNetworkFeeWarningTitle
        }
    }

    var description: String? {
        switch self {
        case .permissionNeeded(let currencyCode):
            return Localization.swappingPermissionSubheader(currencyCode)
        case .refreshRequired(_, let message):
            return message
        case .hasPendingTransaction(let symbol):
            return Localization.warningExpressActiveTransactionMessage(symbol)
        case .hasPendingApproveTransaction:
            return Localization.warningExpressApprovalInProgressMessage
        case .notEnoughFeeForTokenTx(let mainTokenName, let mainTokenSymbol, _):
            return Localization.warningExpressNotEnoughFeeForTokenTxDescription(mainTokenName, mainTokenSymbol)
        case .notEnoughAmountToSwap:
            return Localization.warningExpressTooMinimalAmountDescription
        case .notEnoughBalanceToSwap:
            return Localization.sendNotificationInvalidReserveAmountText
        case .noDestinationTokens(let sourceTokenName):
            return Localization.warningExpressNoExchangeableCoinsDescription(sourceTokenName)
        case .highPriceImpact:
            return Localization.swappingHighPriceImpactDescription
        case .verificationRequired:
            return Localization.expressExchangeNotificationVerificationText
        case .cexOperationFailed:
            return Localization.expressExchangeNotificationFailedText
        case .feeWillBeSubtractFromSendingAmount:
            return Localization.sendNetworkFeeWarningContent
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .permissionNeeded, .hasPendingTransaction, .hasPendingApproveTransaction, .notEnoughAmountToSwap, .notEnoughBalanceToSwap, .noDestinationTokens, .highPriceImpact, .feeWillBeSubtractFromSendingAmount:
            return .secondary
        case .notEnoughFeeForTokenTx, .refreshRequired, .verificationRequired, .cexOperationFailed:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .permissionNeeded:
            return .init(iconType: .image(Assets.swapLock.image))
        case .refreshRequired, .noDestinationTokens, .highPriceImpact, .verificationRequired, .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .hasPendingApproveTransaction:
            return .init(iconType: .progressView)
        case .notEnoughFeeForTokenTx(_, _, let blockchainIconName):
            return .init(iconType: .image(Image(blockchainIconName)))
        case .notEnoughAmountToSwap, .notEnoughBalanceToSwap, .cexOperationFailed:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .hasPendingTransaction:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .permissionNeeded,
             .refreshRequired,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .verificationRequired,
             .feeWillBeSubtractFromSendingAmount:
            return .info
        case .notEnoughFeeForTokenTx,
             .notEnoughAmountToSwap,
             .notEnoughBalanceToSwap,
             .noDestinationTokens,
             .highPriceImpact:
            return .warning
        case .cexOperationFailed:
            return .critical
        }
    }

    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .notEnoughFeeForTokenTx(_, let mainTokenSymbol, _):
            return .openNetworkCurrency(currencySymbol: mainTokenSymbol)
        case .refreshRequired:
            return .refresh
        case .verificationRequired, .cexOperationFailed:
            return .goToProvider
        default:
            return nil
        }
    }

    var isWithLoader: Bool {
        switch self {
        case .refreshRequired:
            return true
        default:
            return false
        }
    }

    var removingOnFullLoadingState: Bool {
        switch self {
        case .noDestinationTokens, .refreshRequired, .verificationRequired, .cexOperationFailed:
            return false
        case .permissionNeeded, .hasPendingTransaction, .hasPendingApproveTransaction, .notEnoughFeeForTokenTx, .notEnoughAmountToSwap, .notEnoughBalanceToSwap, .highPriceImpact, .feeWillBeSubtractFromSendingAmount:
            return true
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Analytics

// [REDACTED_TODO_COMMENT]
extension ExpressNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        return nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        return [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        return false
    }
}
