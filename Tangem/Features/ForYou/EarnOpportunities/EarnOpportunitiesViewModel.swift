//
//  EarnOpportunitiesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class EarnOpportunitiesViewModel: ObservableObject {
    @Published private(set) var state: ViewState

    private let onExploreAllTokens: @MainActor () -> Void

    // [REDACTED_TODO_COMMENT]
    init(state: ViewState = .mock, onExploreAllTokens: @MainActor @escaping () -> Void = {}) {
        self.state = state
        self.onExploreAllTokens = onExploreAllTokens
    }

    func toggle(_ id: String) {
        guard case .content(let content) = state else { return }

        let accounts = content.accounts.map { $0.id == id ? $0.toggledExpansion() : $0 }
        state = .content(.init(subtitle: content.subtitle, accounts: accounts))
    }

    @MainActor
    func exploreAllTokensTapped() {
        onExploreAllTokens()
    }
}
