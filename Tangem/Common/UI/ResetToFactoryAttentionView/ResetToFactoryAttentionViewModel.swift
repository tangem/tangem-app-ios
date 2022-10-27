//
//  ResetToFactoryAttentionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class ResetToFactoryAttentionViewModel: ObservableObject {
    @Published var actionSheet: ActionSheetBinder?
    
    let navigationTitle: String
    let title: String
    let message: String

    let warningText: String?
    let buttonTitle: LocalizedStringKey
    let resetToFactoryAction: () -> Void

    init(
        navigationTitle: String,
        title: String,
        message: String,
        warningText: String? = nil,
        buttonTitle: LocalizedStringKey,
        resetToFactoryAction: @escaping () -> Void
    ) {
        self.navigationTitle = navigationTitle
        self.title = title
        self.message = message
        self.warningText = warningText
        self.buttonTitle = buttonTitle
        self.resetToFactoryAction = resetToFactoryAction
    }
    
    func mainButtonDidTap() {
        showConfirmationAlert()
    }
}

extension ResetToFactoryAttentionViewModel {
    private func showConfirmationAlert() {
        let sheet = ActionSheet(
            title: Text("Are you sure you want to do this?"), // [REDACTED_TODO_COMMENT]
            buttons: [
                .destructive(Text("Reset"), action: {
                    [weak self] in self?.resetToFactoryAction()
                }),
                .cancel()
            ])

        self.actionSheet = ActionSheetBinder(sheet: sheet)
    }
}
