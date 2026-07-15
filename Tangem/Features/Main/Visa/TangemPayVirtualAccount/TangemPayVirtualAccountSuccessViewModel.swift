//
//  TangemPayVirtualAccountSuccessViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
@MainActor
final class TangemPayVirtualAccountSuccessViewModel: ObservableObject, Identifiable {
    let id = UUID()

    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func close() {
        onClose()
    }
}
