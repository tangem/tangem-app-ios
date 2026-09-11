//
//  WelcomeV2ActionSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class WelcomeV2ActionSheetViewModel: ObservableObject {
    let title: String
    let subtitle: String?
    let onBack: (() -> Void)?
    let onClose: () -> Void

    @Published private(set) var items: [WelcomeV2ActionSheetItem]
    @Published var pushedImportSheet: WelcomeV2ImportSheetViewModel?

    init(input: Input) {
        title = input.title
        subtitle = input.subtitle
        items = input.items
        onBack = input.onBack
        onClose = input.onClose
    }

    func update(items: [WelcomeV2ActionSheetItem]) {
        self.items = items
    }
}

// MARK: - Input

extension WelcomeV2ActionSheetViewModel {
    struct Input {
        let title: String
        let subtitle: String?
        let items: [WelcomeV2ActionSheetItem]
        let onBack: (() -> Void)?
        let onClose: () -> Void

        init(
            title: String,
            subtitle: String? = nil,
            items: [WelcomeV2ActionSheetItem],
            onBack: (() -> Void)? = nil,
            onClose: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.items = items
            self.onBack = onBack
            self.onClose = onClose
        }
    }
}
