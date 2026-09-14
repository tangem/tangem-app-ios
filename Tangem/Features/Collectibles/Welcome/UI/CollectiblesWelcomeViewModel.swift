//
//  CollectiblesWelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemUIUtils

final class CollectiblesWelcomeViewModel: ObservableObject {
    // MARK: - Properties

    private weak var routable: (any CollectiblesWelcomeRoutable)?

    // MARK: - Publishers

    @Published private(set) var isOpeningStories = false
    @Published var alert: AlertBinder?

    // MARK: - Init

    init(routable: (any CollectiblesWelcomeRoutable)?) {
        self.routable = routable
    }

    // MARK: - Methods

    // [REDACTED_TODO_COMMENT]
    // `creationFailureAlert` on failure; for now the CTA plays a loader and runs the intro stories.
    func onCreateAccountTap() {
        guard !isOpeningStories else { return }

        isOpeningStories = true

        Task { @MainActor [weak self] in
            try await Task.sleep(for: .seconds(1.5))

            guard let self else { return }

            isOpeningStories = false
            routable?.openStories()
        }
    }

    func onLegalTermsTap(url: URL) {
        Task { @MainActor [weak self] in
            self?.routable?.openLegalTerms(url: url)
        }
    }
}

// MARK: - Alerts

private extension CollectiblesWelcomeViewModel {
    // [REDACTED_TODO_COMMENT]
    static let creationFailureAlert = AlertBinder(
        title: Localization.commonSomethingWentWrong,
        message: "We couldn't create Packs account. Please try again later."
    )
}
