//
//  PaymentAccountGlobalStateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PaymentAccountGlobalStateProvider {
    var hasTangemPayAccount: Bool { get }
    var hasVirtualAccount: Bool { get }

    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable
    func unregister<U>(forIdentifier identifier: U) where U: Hashable
}
