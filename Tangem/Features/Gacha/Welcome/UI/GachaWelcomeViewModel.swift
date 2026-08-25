//
//  GachaWelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class GachaWelcomeViewModel: ObservableObject {
    // MARK: - Properties

    private weak var routable: (any GachaWelcomeRoutable)?

    // MARK: - Publishers

    @Published private(set) var isOpeningStories = false

    // MARK: - Init

    init(routable: (any GachaWelcomeRoutable)?) {
        self.routable = routable
    }

    // MARK: - Methods

    // [REDACTED_TODO_COMMENT]
    // for now the CTA plays a loader and runs the intro stories.
    func onCreateAccountTap() {
        guard !isOpeningStories else { return }

        isOpeningStories = true

        Task { @MainActor [weak self] in
            try await Task.sleep(for: .seconds(1.5))

            self?.routable?.openStories()
        }
    }
}
