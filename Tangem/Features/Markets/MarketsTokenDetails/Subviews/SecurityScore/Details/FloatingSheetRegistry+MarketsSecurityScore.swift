//
//  FloatingSheetRegistry+MarketsSecurityScore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerMarketsSecurityScoreFloatingSheets() {
        register(MarketsTokenDetailsSecurityScoreDetailsViewModel.self) { viewModel in
            MarketsTokenDetailsSecurityScoreDetailsRedesignedView(viewModel: viewModel)
        }
    }
}
