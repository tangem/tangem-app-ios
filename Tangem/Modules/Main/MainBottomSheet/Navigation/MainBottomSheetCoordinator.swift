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

    @Published var manageTokensCoordinator: ManageTokensCoordinator?

    // MARK: - Child view models

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel? = nil
    private lazy var __headerViewModel = MainBottomSheetHeaderViewModel()

    @Published private(set) var contentViewModel: MainBottomSheetContentViewModel? = nil
    private lazy var __contentViewModel = MainBottomSheetContentViewModel(
        manageTokensViewModel: manageTokensCoordinator?.manageTokensViewModel,
        searchTextPublisher: __headerViewModel.enteredSearchTextPublisher
    )

    // MARK: - Private Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        start()

        bind()
    }

    func start(with options: Options = .init()) {
        manageTokensCoordinator = .init(dismissAction: dismissAction, popToRootAction: popToRootAction)
        manageTokensCoordinator?.start(with: .init())
    }

    private func bind() {
        let bottomSheetVisibilityPublisher = bottomSheetVisibility
            .isShown
            .share(replay: 1)

        bottomSheetVisibilityPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__headerViewModel : nil
            }
            .assign(to: \.headerViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        bottomSheetVisibilityPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__contentViewModel : nil
            }
            .assign(to: \.contentViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension MainBottomSheetCoordinator {
    struct Options {}
}
