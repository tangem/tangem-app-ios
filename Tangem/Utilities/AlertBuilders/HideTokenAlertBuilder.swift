//
//  HideTokenAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct HideTokenAlertBuilder {
    func hideTokenAlert(tokenItem: TokenItem, hideAction: @escaping () -> Void, cancelAction: @escaping () -> Void = {}) -> AlertBinder {
        return AlertBinder(
            alert: Alert(
                title: Text(Localization.tokenDetailsHideAlertTitle(tokenItem.name)),
                message: Text(Localization.tokenDetailsHideAlertMessage),
                primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                secondaryButton: .cancel(cancelAction)
            )
        )
    }

    func unableToHideTokenAlert(tokenItem: TokenItem, cancelAction: @escaping () -> Void = {}) -> AlertBinder {
        let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.name)

        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenItem.name,
            tokenItem.currencySymbol,
            tokenItem.blockchain.displayName
        )

        return AlertBinder(
            alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text(Localization.commonOk), action: cancelAction)
            )
        )
    }
}
