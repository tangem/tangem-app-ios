//
//  UserSettingsAccountRowViewData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts

struct UserSettingsAccountRowViewData: Identifiable {
    let id: String
    let name: String
    let accountIconViewData: AccountIconView.AccountIconViewData
    let description: String
    let onTap: () -> Void
}
