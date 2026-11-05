//
//  UserWalletLinkRequester.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum UserWalletLinkResult {
    case linked
    case dismissed
}

@MainActor
protocol UserWalletLinkRequester {
    func requestLink(for userWalletModel: any UserWalletModel, completion: @escaping (UserWalletLinkResult) -> Void)
}

// MARK: - Dependency injection

private struct UserWalletLinkRequesterKey: InjectionKey {
    static var currentValue: any UserWalletLinkRequester = CommonUserWalletLinkRequester()
}

extension InjectedValues {
    var userWalletLinkRequester: any UserWalletLinkRequester {
        get { Self[UserWalletLinkRequesterKey.self] }
        set { Self[UserWalletLinkRequesterKey.self] = newValue }
    }
}
