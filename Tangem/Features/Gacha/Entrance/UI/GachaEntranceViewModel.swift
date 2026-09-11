//
//  GachaEntranceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class GachaEntranceViewModel: ObservableObject {
    // MARK: - Properties

    private let accountStatusProvider: any GachaAccountStatusProvider
    private let userWalletModelsProvider: () -> [UserWalletModel]
    private let floatingSheetPresenter: FloatingSheetPresenter

    private(set) var openingTask: Task<Void, Never>?

    /// Weak on purpose: the sheet infrastructure owns the selector, so any dismissal path clears this by itself.
    private weak var presentedWalletSelector: AccountSelectorViewModel?

    // MARK: - Init

    init(
        accountStatusProvider: any GachaAccountStatusProvider = GachaAccountStatusMockProvider(),
        userWalletModelsProvider: @escaping () -> [UserWalletModel],
        floatingSheetPresenter: FloatingSheetPresenter = InjectedValues[\.floatingSheetPresenter]
    ) {
        self.accountStatusProvider = accountStatusProvider
        self.userWalletModelsProvider = userWalletModelsProvider
        self.floatingSheetPresenter = floatingSheetPresenter
    }

    deinit {
        openingTask?.cancel()
    }

    // MARK: - Methods

    func openGacha(onOpen: @MainActor @escaping (GachaCoordinator.Options) -> Void) {
        guard openingTask == nil, presentedWalletSelector == nil else { return }

        let userWalletModels = userWalletModelsProvider()

        guard let firstUserWalletModel = userWalletModels.first else { return }

        guard userWalletModels.count > 1 else {
            resolveDestination(for: firstUserWalletModel, onOpen: onOpen)
            return
        }

        presentWalletSelector(with: userWalletModels, onOpen: onOpen)
    }
}

// MARK: - Private logic

private extension GachaEntranceViewModel {
    func presentWalletSelector(
        with userWalletModels: [UserWalletModel],
        onOpen: @MainActor @escaping (GachaCoordinator.Options) -> Void
    ) {
        Task { @MainActor [weak self, floatingSheetPresenter] in
            let accountSelectorViewModel = AccountSelectorViewModel(
                userWalletModels: userWalletModels,
                preferredDisplayMode: .wallets
            ) { selectedCell in
                floatingSheetPresenter.removeActiveSheet()
                self?.resolveDestination(for: selectedCell.userWalletModel, onOpen: onOpen)
            }

            self?.presentedWalletSelector = accountSelectorViewModel

            floatingSheetPresenter.enqueue(
                sheet: GachaWalletSelectorViewModel(
                    accountSelectorViewModel: accountSelectorViewModel,
                    close: floatingSheetPresenter.removeActiveSheet
                )
            )
        }
    }

    // [REDACTED_TODO_COMMENT]
    func resolveDestination(
        for userWalletModel: UserWalletModel,
        onOpen: @MainActor @escaping (GachaCoordinator.Options) -> Void
    ) {
        guard openingTask == nil else { return }

        openingTask = Task { @MainActor [weak self, accountStatusProvider] in
            defer { self?.openingTask = nil }

            do {
                let accountStatus = try await accountStatusProvider.load()

                switch accountStatus {
                case .exists:
                    onOpen(.init(destination: .main))
                case .missing:
                    onOpen(.init(destination: .welcome))
                }
            } catch is CancellationError {
            } catch {
                AppLogger.error("Gacha account status loading failed", error: error)
            }
        }
    }
}
