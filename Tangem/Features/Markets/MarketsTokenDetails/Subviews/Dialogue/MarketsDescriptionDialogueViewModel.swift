//
//  MarketsDescriptionDialogueViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class MarketsDescriptionDialogueViewModel: FloatingSheetContentViewModel {
    let title: String
    let descriptionText: String
    let showGeneratedWithAI: Bool
    let onGenerateAITapAction: (() -> Void)?
    let closeAction: () -> Void

    init(
        title: String,
        descriptionText: String,
        showGeneratedWithAI: Bool = false,
        onGenerateAITapAction: (() -> Void)? = nil,
        closeAction: @escaping () -> Void
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.showGeneratedWithAI = showGeneratedWithAI
        self.onGenerateAITapAction = onGenerateAITapAction
        self.closeAction = closeAction
    }
}
