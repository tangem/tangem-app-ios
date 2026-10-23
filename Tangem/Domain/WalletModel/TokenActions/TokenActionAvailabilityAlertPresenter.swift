//
//  TokenActionAvailabilityAlertPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUIUtils

/// The `receiveStatus` / `buyStatus` / `swapSourceStatus` / `swapReceiveStatus` alerts stop the action, while the `warning` alert lets the user
/// proceed with it right from the alert or leave for support, which runs `cancelAction`.
enum TokenActionAvailabilityAlertPresenter {
    static func presentOrProceed(
        handler: inout AlertBinder?,
        receiveStatus: TokenActionAvailabilityProvider.ReceiveActionAvailabilityStatus? = nil,
        buyStatus: TokenActionAvailabilityProvider.BuyActionAvailabilityStatus? = nil,
        swapSourceStatus: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus? = nil,
        swapReceiveStatus: TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus? = nil,
        sellStatus: TokenActionAvailabilityProvider.SellActionAvailabilityStatus? = nil,
        warning: TokenActionAvailabilityProvider.TokenActionAvailabilityWarningType? = nil,
        action: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        if let alert = alert(
            receiveStatus: receiveStatus,
            buyStatus: buyStatus,
            swapSourceStatus: swapSourceStatus,
            swapReceiveStatus: swapReceiveStatus,
            sellStatus: sellStatus,
            warning: warning,
            action: action,
            cancelAction: cancelAction
        ) {
            handler = alert
            return
        }

        action()
    }

    static func presentOrProceed(
        presenter: AlertPresenter,
        receiveStatus: TokenActionAvailabilityProvider.ReceiveActionAvailabilityStatus? = nil,
        buyStatus: TokenActionAvailabilityProvider.BuyActionAvailabilityStatus? = nil,
        swapSourceStatus: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus? = nil,
        swapReceiveStatus: TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus? = nil,
        sellStatus: TokenActionAvailabilityProvider.SellActionAvailabilityStatus? = nil,
        warning: TokenActionAvailabilityProvider.TokenActionAvailabilityWarningType? = nil,
        action: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        if let alert = alert(
            receiveStatus: receiveStatus,
            buyStatus: buyStatus,
            swapSourceStatus: swapSourceStatus,
            swapReceiveStatus: swapReceiveStatus,
            sellStatus: sellStatus,
            warning: warning,
            action: action,
            cancelAction: cancelAction
        ) {
            presenter.present(alert: alert)
            return
        }

        action()
    }

    private static func alert(
        receiveStatus: TokenActionAvailabilityProvider.ReceiveActionAvailabilityStatus?,
        buyStatus: TokenActionAvailabilityProvider.BuyActionAvailabilityStatus?,
        swapSourceStatus: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus?,
        swapReceiveStatus: TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus?,
        sellStatus: TokenActionAvailabilityProvider.SellActionAvailabilityStatus?,
        warning: TokenActionAvailabilityProvider.TokenActionAvailabilityWarningType?,
        action: @escaping () -> Void,
        cancelAction: (() -> Void)?
    ) -> AlertBinder? {
        let alertBuilder = TokenActionAvailabilityAlertBuilder()

        let receiveAlert = receiveStatus.flatMap { alertBuilder.alert(for: $0) }
        let buyAlert = buyStatus.flatMap { alertBuilder.alert(for: $0) }
        let swapAlert = swapSourceStatus.flatMap { alertBuilder.alert(for: $0) }
        let swapReceiveAlert = swapReceiveStatus.flatMap { alertBuilder.alert(for: $0) }
        let sellAlert = sellStatus.flatMap { alertBuilder.alert(for: $0) }
        let warningAlert = warning.flatMap {
            alertBuilder.alert(for: $0, continueAction: action, cancelAction: cancelAction)
        }

        return receiveAlert ?? buyAlert ?? swapAlert ?? swapReceiveAlert ?? sellAlert ?? warningAlert
    }
}
