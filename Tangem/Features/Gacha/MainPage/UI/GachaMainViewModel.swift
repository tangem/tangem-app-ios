//
//  GachaMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class GachaMainViewModel: ObservableObject {
    // MARK: - Properties

    let accountViewModel = GachaAccountViewModel(provider: GachaAccountSummaryMockProvider())
    let loreTabsViewModel = GachaLoreTabsViewModel(provider: GachaLoresMockProvider())

    // MARK: - Methods

    func onActionSelected(_ action: GachaMainView.ActionsMenu.Action) {
        // [REDACTED_TODO_COMMENT]
        switch action {
        case .activityLog, .deliveries, .howItWorks, .getAssistance:
            break
        }
    }
}
