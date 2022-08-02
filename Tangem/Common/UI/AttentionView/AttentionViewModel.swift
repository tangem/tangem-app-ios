//
//  AttentionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class AttentionViewModel: ObservableObject {
    @Published var isWarningChecked: Bool

    let navigationTitle: String
    let title: String
    let message: String

    let warningText: String?
    let buttonTitle: LocalizedStringKey
    let mainButtonAction: () -> Void

    init(
        isWarningChecked: Bool,
        navigationTitle: String,
        title: String,
        message: String,
        warningText: String? = nil,
        buttonTitle: LocalizedStringKey,
        mainButtonAction: @escaping () -> Void
    ) {
        self.isWarningChecked = isWarningChecked
        self.navigationTitle = navigationTitle
        self.title = title
        self.message = message
        self.warningText = warningText
        self.buttonTitle = buttonTitle
        self.mainButtonAction = mainButtonAction
    }
}
