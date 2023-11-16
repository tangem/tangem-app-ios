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
    private lazy var __manageTokensCoordinator = ManageTokensCoordinator()

    // MARK: - Child view models

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel? = nil
    private lazy var __headerViewModel = MainBottomSheetHeaderViewModel()

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

    func start(with options: Options = .init()) {
        __manageTokensCoordinator.start(with: .init(searchTextPublisher: __headerViewModel.enteredSearchTextPublisher))
    }

    private func bind() {
        let bottomSheetVisibilityPublisher = bottomSheetVisibility
            .isShownPublisher
            .share(replay: 1)

        bottomSheetVisibilityPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__headerViewModel : nil
            }
            .assign(to: \.headerViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        bottomSheetVisibilityPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__manageTokensCoordinator : nil
            }
            .assign(to: \.manageTokensCoordinator, on: self, ownership: .weak)
            .store(in: &bag)

        bottomSheetVisibilityPublisher
            .map { [weak self] isShown in
                return isShown ? self?.__overlayViewModel : nil
            }
            .assign(to: \.overlayViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension MainBottomSheetCoordinator {
    struct Options {}
}

extension MainBottomSheetCoordinator: MainBottomSheetContentRoutable {
    func openTokenSelector(coinId: String, with tokenItems: [TokenItem]) {
        let coordinator = ManageTokensNetworkSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(coinId: coinId, tokenItems: tokenItems))
        networkSelectorCoordinator = coordinator
    }

    func showGenerateAddressesWarning(
        numberOfNetworks: Int,
        currentWalletNumber: Int,
        totalWalletNumber: Int,
        action: @escaping () -> Void
    ) {
        __overlayViewModel = GenerateAddressesViewModel(
            numberOfNetworks: numberOfNetworks,
            currentWalletNumber: currentWalletNumber,
            totalWalletNumber: totalWalletNumber,
            didTapGenerate: action
        )
    }

    func hideGenerateAddressesWarning() {
        __overlayViewModel = nil
    }
}
