//
//  WelcomeV2ImportSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class WelcomeV2ImportSheetViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let onClose: () -> Void

    @Published private(set) var items: [WelcomeV2ImportSheetItem]

    init(input: Input) {
        title = input.title
        subtitle = input.subtitle
        items = input.items
        onBack = input.onBack
        onClose = input.onClose
    }

    func update(items: [WelcomeV2ImportSheetItem]) {
        self.items = items
    }
}

// MARK: - Input

extension WelcomeV2ImportSheetViewModel {
    struct Input {
        let title: String
        let subtitle: String?
        let items: [WelcomeV2ImportSheetItem]
        let onBack: () -> Void
        let onClose: () -> Void
    }
}
