// 
//  AppSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

final class AppSettingsViewModel: ObservableObject {
    // MARK: ViewState

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    init(
        coordinator: AppSettingsRoutable
    ) {
        self.coordinator = coordinator
    }
}
