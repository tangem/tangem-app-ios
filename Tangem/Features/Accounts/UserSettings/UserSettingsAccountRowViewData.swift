//
//  UserSettingsAccountRowViewData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import Combine

struct UserSettingsAccountRowViewData: Identifiable {
    let id: AnyHashable
    let name: String
    let accountIconViewData: AccountIconView.ViewData
    let description: String
    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>?

    let onTap: () -> Void
}
