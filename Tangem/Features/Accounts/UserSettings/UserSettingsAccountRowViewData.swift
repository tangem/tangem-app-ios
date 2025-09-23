//
//  UserSettingsAccountRowViewData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import SwiftUI
import TangemAccounts

struct UserSettingsAccountRowViewData: Identifiable {
    let id: String
    let name: String
    let iconNameMode: AccountIconView.NameMode
    let description: String
    let iconColor: Color
    let onTap: () -> Void
}
