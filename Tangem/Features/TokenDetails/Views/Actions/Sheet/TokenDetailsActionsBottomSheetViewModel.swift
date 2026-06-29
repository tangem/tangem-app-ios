//
//  TokenDetailsActionsBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class TokenDetailsActionsBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    let title: String
    let onClose: () -> Void

    @Published private(set) var state: State

    init(
        title: String,
        items: [TokenDetailsActionRowItem],
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.onClose = onClose
        state = .actions(items)
    }

    func showReceive(_ viewModel: ReceiveMainViewModel) {
        state = .receive(viewModel)
    }
}

// MARK: - State

extension TokenDetailsActionsBottomSheetViewModel {
    enum State {
        case actions([TokenDetailsActionRowItem])
        case receive(ReceiveMainViewModel)

        var id: String {
            switch self {
            case .actions: return "actions"
            case .receive: return "receive"
            }
        }
    }
}
