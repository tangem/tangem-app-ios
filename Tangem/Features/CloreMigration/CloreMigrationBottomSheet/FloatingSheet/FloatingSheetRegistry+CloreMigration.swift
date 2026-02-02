//
//  FloatingSheetRegistry+CloreMigration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

public extension FloatingSheetRegistry {
    func registerCloreMigrationFloatingSheets() {
        register(CloreMigrationViewModel.self) { viewModel in
            CloreMigrationView(viewModel: viewModel)
        }
    }
}
