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

    // [REDACTED_TODO_COMMENT]
    let devnet: CollectiblesDevnetMenuViewModel?

    // MARK: - Init

    init(routable: (any CollectiblesActionsMenuRoutable)?, devnet: CollectiblesDevnetMenuViewModel? = nil) {
        self.routable = routable
        self.devnet = devnet
    }

    // MARK: - Methods

    func onHowItWorksTap() {
        routable?.openHowItWorks()
    }

    func onSupportTap() {
        routable?.openSupport()
    }
}
