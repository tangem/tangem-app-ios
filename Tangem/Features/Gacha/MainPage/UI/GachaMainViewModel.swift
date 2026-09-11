//
//  GachaMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

final class GachaMainViewModel: ObservableObject {
    // MARK: - Properties

    let accountViewModel = GachaAccountViewModel(provider: GachaAccountSummaryMockProvider())
    let loreTabsViewModel = GachaLoreTabsViewModel(provider: GachaLoresMockProvider())
    let packsViewModel = GachaPacksViewModel(provider: GachaPacksMockProvider())

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        bind()
    }

    // MARK: - Methods

    func onActionSelected(_ action: GachaMainView.ActionsMenu.Action) {
        // [REDACTED_TODO_COMMENT]
        switch action {
        case .activityLog, .deliveries, .howItWorks, .getAssistance:
            break
        }
    }
}

// MARK: - Private logic

private extension GachaMainViewModel {
    func bind() {
        loreTabsViewModel.$selectedTab
            .map(\.kind.loreID)
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, loreID in
                viewModel.packsViewModel.reload(loreID: loreID)
            }
            .store(in: &bag)
    }
}
