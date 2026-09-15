//
//  CollectiblesActionsMenuViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
final class CollectiblesActionsMenuViewModel {
    // MARK: - Properties

    private weak var routable: (any CollectiblesActionsMenuRoutable)?

    // MARK: - Init

    init(routable: (any CollectiblesActionsMenuRoutable)?) {
        self.routable = routable
    }

    // MARK: - Methods

    func onHowItWorksTap() {
        routable?.openHowItWorks()
    }

    func onSupportTap() {
        routable?.openSupport()
    }
}
