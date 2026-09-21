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

    @MainActor
    private var isResolvingDestination = false

    // MARK: - Init

    init(
        userWalletModelsProvider: @escaping () -> [UserWalletModel],
        floatingSheetPresenter: FloatingSheetPresenter = InjectedValues[\.floatingSheetPresenter]
    ) {
        self.userWalletModelsProvider = userWalletModelsProvider
        self.floatingSheetPresenter = floatingSheetPresenter
    }

    // MARK: - Methods

    @MainActor
    func openCollectibles(
        isRegionRestricted: Bool,
        onRestricted: @MainActor @escaping () -> Void,
        onOpen: @MainActor @escaping (CollectiblesCoordinator.Options) -> Void
    ) {
        let userWalletModels = userWalletModelsProvider()

        guard let firstUserWalletModel = userWalletModels.first else { return }

        guard userWalletModels.count > 1 else {
            Task { @MainActor [weak self] in
                await self?.resolveDestination(
                    for: firstUserWalletModel,
                    isRegionRestricted: isRegionRestricted,
                    onRestricted: onRestricted,
                    onOpen: onOpen
                )
            }
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
                await self?.resolveDestination(
                    for: selectedCell.userWalletModel,
                    isRegionRestricted: isRegionRestricted,
                    onRestricted: onRestricted,
                    onOpen: onOpen
                )
            }
        }

        floatingSheetPresenter.enqueue(
            sheet: WalletSelectorSheetViewModel(
                accountSelectorViewModel: accountSelectorViewModel,
                close: floatingSheetPresenter.removeActiveSheet
            )
        )
    }

    /// Unresolved means unknown, not "no account": in a restricted region the two answers differ.
    ///
    /// The wait spans a tap, so taps that arrive during it are dropped rather than each opening a screen.
    @MainActor
    func resolveDestination(
        for userWalletModel: UserWalletModel,
        isRegionRestricted: Bool,
        onRestricted: @MainActor () -> Void,
        onOpen: @MainActor (CollectiblesCoordinator.Options) -> Void
    ) async {
        guard !isResolvingDestination else {
            return
        }

        isResolvingDestination = true
        defer { isResolvingDestination = false }

        let accountModel = AccountModelsAggregator(.collectibles)
            .model(from: userWalletModel.accountModelsManager)

        if accountModel?.state == .unresolved {
            await accountModel?.refreshState()
        }

        let hasCollectiblesAccount = accountModel?.state.isAccountVisible ?? false

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
