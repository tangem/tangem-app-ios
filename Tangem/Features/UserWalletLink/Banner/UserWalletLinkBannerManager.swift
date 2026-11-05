//
//  UserWalletLinkBannerManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol UserWalletLinkBannerManager: AnyObject {
    var event: GeneralNotificationEvent? { get }

    func load(onUpdate: @escaping () -> Void)
    func link()
}
