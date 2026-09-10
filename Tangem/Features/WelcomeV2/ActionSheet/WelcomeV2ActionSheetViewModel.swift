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

    /// The `Sheet` value this sheet reports in analytics; lives on the sheet so it can't
    /// outlive it, unlike a mirror flag on the coordinator.
    let analyticsSheet: Analytics.ParameterValue

    @Published private(set) var items: [WelcomeV2ActionSheetItem]
    @Published var pushedImportSheet: WelcomeV2ImportSheetViewModel?

    init(input: Input) {
        title = input.title
        subtitle = input.subtitle
        analyticsSheet = input.analyticsSheet
        items = input.items
        onBack = input.onBack
        onClose = input.onClose
    }

    func update(items: [WelcomeV2ActionSheetItem]) {
        self.items = items
    }

    func setLoading(_ isLoading: Bool, for itemId: String) {
        items = items.map { item in
            var updated = item
            updated.isLoading = item.id == itemId ? isLoading : false
            return updated
        }
    }
}

// MARK: - Input

extension WelcomeV2ActionSheetViewModel {
    struct Input {
        let title: String
        let subtitle: String?
        let analyticsSheet: Analytics.ParameterValue
        let items: [WelcomeV2ActionSheetItem]
        let onBack: (() -> Void)?
        let onClose: () -> Void

        init(
            title: String,
            subtitle: String? = nil,
            analyticsSheet: Analytics.ParameterValue,
            items: [WelcomeV2ActionSheetItem],
            onBack: (() -> Void)? = nil,
            onClose: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.analyticsSheet = analyticsSheet
            self.items = items
            self.onBack = onBack
            self.onClose = onClose
        }
    }
}
