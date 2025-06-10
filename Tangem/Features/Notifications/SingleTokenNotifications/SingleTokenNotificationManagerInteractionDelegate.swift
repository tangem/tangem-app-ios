//
//  SingleTokenNotificationManagerInteractionDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SingleTokenNotificationManagerInteractionDelegate: AnyObject {
    func confirmDiscardingUnfulfilledAssetRequirements(
        with configuration: TokenNotificationEvent.UnfulfilledRequirementsConfiguration,
        confirmationAction: @escaping () -> Void
    )
}
