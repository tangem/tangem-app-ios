//
//  ScanCardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

final class ScanCardSettingsViewModel: ObservableObject {
    // MARK: ViewState

    // MARK: Dependencies

    private unowned let coordinator: ScanCardSettingsRoutable

    init(
        coordinator: ScanCardSettingsRoutable
    ) {
        self.coordinator = coordinator
    }
}
