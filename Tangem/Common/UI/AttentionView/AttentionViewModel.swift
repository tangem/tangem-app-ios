//
//  AttentionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Foundation

class AttentionViewModel: ObservableObject {
    @Published var isCheckedWarning: Bool

    let navigationTitle: LocalizedStringKey
    let title: String
    let message: String

    let warningText: String?
    let buttonTitle: LocalizedStringKey
    let mainButtonAction: () -> Void

    init(
        isCheckedWarning: Bool,
        navigationTitle: LocalizedStringKey,
        title: String,
        message: String,
        warningText: String? = nil,
        buttonTitle: LocalizedStringKey,
        mainButtonAction: @escaping () -> Void
    ) {
        self.isCheckedWarning = isCheckedWarning
        self.navigationTitle = navigationTitle
        self.title = title
        self.message = message
        self.warningText = warningText
        self.buttonTitle = buttonTitle
        self.mainButtonAction = mainButtonAction
    }
}
