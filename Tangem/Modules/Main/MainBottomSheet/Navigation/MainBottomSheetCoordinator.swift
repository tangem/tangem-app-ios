//
//  MainBottomSheetCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class MainBottomSheetCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    // MARK: - Child coordinators

    @Published var marketsCoordinator: MarketsCoordinator?
    @Published var shouldDissmis: Bool = false

    // MARK: - Child view models

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel?
    private lazy var __headerViewModel = MainBottomSheetHeaderViewModel()

    @Published private(set) var overlayViewModel: MainBottomSheetOverlayViewModel?

    // MARK: - Private Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        bind()
    }

    func start(with options: Void = ()) {
        setupManageTokens()
    }

    func onBottomScrollableSheetStateChange(_ state: BottomScrollableSheetState) {
        __headerViewModel.onBottomScrollableSheetStateChange(state)
        marketsCoordinator?.onBottomScrollableSheetStateChange(state)
    }

    private func bind() {
        bottomSheetVisibility
            .isShownPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__headerViewModel : nil
            }
            .assign(to: \.headerViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupManageTokens() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.shouldDissmis = true
        }

        let coordinator = MarketsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(searchTextPublisher: __headerViewModel.enteredSearchTextPublisher))
        marketsCoordinator = coordinator
    }
}
