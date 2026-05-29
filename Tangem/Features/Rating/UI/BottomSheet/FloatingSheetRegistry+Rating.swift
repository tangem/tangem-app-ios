//
//  FloatingSheetRegistry+Rating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerRatingFloatingSheets() {
        register(
            RatingFeedbackBottomSheetViewModel.self,
            viewBuilder: RatingFeedbackBottomSheetView.init
        )
    }
}
