//
//  CollectiblesEntranceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CollectiblesEntranceViewModel: ObservableObject {
    // MARK: - Properties

    private let userWalletModelsProvider: () -> [UserWalletModel]
    private let floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Init

    init(
        userWalletModelsProvider: @escaping () -> [UserWalletModel],
        floatingSheetPresenter: FloatingSheetPresenter = InjectedValues[\.floatingSheetPresenter]
    ) {
        self.userWalletModelsProvider = userWalletModelsProvider
        self.floatingSheetPresenter = floatingSheetPresenter
    }

    // MARK: - Methods

    /// The open sheet swallows background taps itself, and the destination resolves within the tap,
    /// so a repeat tap has nothing left to guard against.
    @MainActor
    func openCollectibles(
        isRegionRestricted: Bool,
        onRestricted: @MainActor @escaping () -> Void,
        onOpen: @MainActor @escaping (CollectiblesCoordinator.Options) -> Void
    ) {
        let userWalletModels = userWalletModelsProvider()

        guard let firstUserWalletModel = userWalletModels.first else { return }

        guard userWalletModels.count > 1 else {
            resolveDestination(
                for: firstUserWalletModel,
                isRegionRestricted: isRegionRestricted,
                onRestricted: onRestricted,
                onOpen: onOpen
            )
            return
        }

        presentWalletSelector(
            with: userWalletModels,
            isRegionRestricted: isRegionRestricted,
            onRestricted: onRestricted,
            onOpen: onOpen
        )
    }
}

// MARK: - Private logic

private extension CollectiblesEntranceViewModel {
    @MainActor
    func presentWalletSelector(
        with userWalletModels: [UserWalletModel],
        isRegionRestricted: Bool,
        onRestricted: @MainActor @escaping () -> Void,
        onOpen: @MainActor @escaping (CollectiblesCoordinator.Options) -> Void
    ) {
        let accountSelectorViewModel = AccountSelectorViewModel(
            userWalletModels: userWalletModels,
            preferredDisplayMode: .wallets
        ) { [weak self, floatingSheetPresenter] selectedCell in
            floatingSheetPresenter.removeActiveSheet()
            // The selector types its callback without isolation, so the hop belongs to its API, not to this flow
            Task { @MainActor in
                self?.resolveDestination(
                    for: selectedCell.userWalletModel,
                    isRegionRestricted: isRegionRestricted,
                    onRestricted: onRestricted,
                    onOpen: onOpen
                )
            }
        }

        floatingSheetPresenter.enqueue(
            sheet: CollectiblesWalletSelectorViewModel(
                accountSelectorViewModel: accountSelectorViewModel,
                close: floatingSheetPresenter.removeActiveSheet
            )
        )
    }

    /// The account list answers this outright — no chain read, nothing to fail, between the tap and the screen.
    @MainActor
    func resolveDestination(
        for userWalletModel: UserWalletModel,
        isRegionRestricted: Bool,
        onRestricted: @MainActor () -> Void,
        onOpen: @MainActor (CollectiblesCoordinator.Options) -> Void
    ) {
        let hasCollectiblesAccount = CollectiblesAccountAggregator.collectiblesAccountModel(from: userWalletModel.accountModelsManager) != nil

        switch Destination(hasAccount: hasCollectiblesAccount, isRestricted: isRegionRestricted) {
        case .welcome:
            onOpen(.init(destination: .welcome, userWalletModel: userWalletModel))
        case .main:
            onOpen(.init(destination: .main, userWalletModel: userWalletModel))
        case .regionRestrictions:
            onRestricted()
        }
    }
}

// MARK: - Destination

extension CollectiblesEntranceViewModel {
    enum Destination: Equatable {
        case welcome
        case main
        case regionRestrictions

        init(hasAccount: Bool, isRestricted: Bool) {
            switch (hasAccount, isRestricted) {
            case (true, _): self = .main
            case (false, true): self = .regionRestrictions
            case (false, false): self = .welcome
            }
        }
    }
}
