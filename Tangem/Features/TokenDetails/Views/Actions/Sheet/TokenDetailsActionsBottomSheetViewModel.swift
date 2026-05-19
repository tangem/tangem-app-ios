//
//  TokenDetailsActionsBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class TokenDetailsActionsBottomSheetViewModel: FloatingSheetContentViewModel {
    let title: String
    let items: [TokenDetailsActionRowItem]
    let onClose: () -> Void

    init(
        title: String,
        items: [TokenDetailsActionRowItem],
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.items = items
        self.onClose = onClose
    }
}
