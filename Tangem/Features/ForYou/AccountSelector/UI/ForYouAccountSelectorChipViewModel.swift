//
//  ForYouAccountSelectorChipViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class ForYouAccountSelectorChipViewModel: ObservableObject {
    // MARK: - Typealias

    typealias SelectionScopePublisher = ForYouAccountSelectionResolver.SelectionScopePublisher
    typealias SelectionState = ForYouAccountSelectorChip.SelectionState

    // MARK: - Properties

    private let selectionScopePublisher: SelectionScopePublisher
    private let resetSelectionAction: () -> Void

    private weak var router: ForYouAccountSelectorRoutable?

    private var subscription: AnyCancellable?

    // MARK: - Publishers

    @Published private(set) var selection: SelectionState = .all

    // MARK: - Init

    init(
        selectionScopePublisher: SelectionScopePublisher,
        resetSelectionAction: @escaping () -> Void,
        router: ForYouAccountSelectorRoutable? = nil
    ) {
        self.selectionScopePublisher = selectionScopePublisher
        self.resetSelectionAction = resetSelectionAction
        self.router = router

        bind()
    }

    // MARK: - Internal methods

    @MainActor
    func openAccountSelector() {
        router?.openAccountSelector()
    }

    func resetSelection() {
        resetSelectionAction()
    }
}

private extension ForYouAccountSelectorChipViewModel {
    // MARK: - Private

    func bind() {
        subscription = selectionScopePublisher
            .map(Self.selectionState)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, selection in
                viewModel.selection = selection
            }
    }

    static func selectionState(for scope: ForYouAccountSelectionResolver.SelectionScope) -> SelectionState {
        guard !scope.coversAllAccounts else {
            return .all
        }

        if scope.selected.count == 1, let name = scope.selected.first?.account.name {
            return .single(name: name)
        }

        return .multiple(count: scope.selected.count)
    }
}
