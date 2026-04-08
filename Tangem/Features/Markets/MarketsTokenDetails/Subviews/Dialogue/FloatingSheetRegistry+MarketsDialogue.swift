//
//  FloatingSheetRegistry+MarketsDialogue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerMarketsDialogueFloatingSheets() {
        register(MarketsDescriptionDialogueViewModel.self) { viewModel in
            MarketsDescriptionDialogueView(viewModel: viewModel)
        }
    }
}
