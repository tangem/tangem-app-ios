//
//  SendFeeSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class SendFeeSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var feeSelectorViewModel: FeeSelectorViewModel

    init(feeSelectorViewModel: FeeSelectorViewModel) {
        self.feeSelectorViewModel = feeSelectorViewModel
    }

    func userDidTapDismissButton() {
        feeSelectorViewModel.userDidTapDismissButton()
    }
}
