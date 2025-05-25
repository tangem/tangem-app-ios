//
//  WalletConnectWalletSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct SwiftUI.Image
import TangemLocalization

@MainActor
final class WalletConnectWalletSelectorViewModel: ObservableObject {
    private let backAction: () -> Void
    private let userWalletSelectedAction: (UserWalletModel) -> Void

    private let balanceStateBuilder: LoadableTokenBalanceViewStateBuilder

    private var walletImagesLoadingTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable>

    let selectionAnimationDuration: TimeInterval = 0.3

    @Published private(set) var state: WalletConnectWalletSelectorViewState

    init(
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        backAction: @escaping () -> Void,
        userWalletSelectedAction: @escaping (UserWalletModel) -> Void
    ) {
        self.backAction = backAction
        self.userWalletSelectedAction = userWalletSelectedAction

        state = .loading(userWallets: userWallets, selectedWallet: selectedUserWallet)

        balanceStateBuilder = LoadableTokenBalanceViewStateBuilder()
        cancellables = []

        loadImages(for: userWallets)
        loadBalances(for: userWallets)
    }

    deinit {
        walletImagesLoadingTask?.cancel()
    }

    private func loadImages(for userWallets: [any UserWalletModel]) {
        walletImagesLoadingTask = Task {
            await withTaskGroup(of: (Int, SwiftUI.Image).self) { [weak self] taskGroup in
                for (index, userWallet) in userWallets.enumerated() {
                    taskGroup.addTask {
                        let image = await userWallet.cardImageProvider.loadSmallImage().image
                        return (index, image)
                    }
                }

                for await (index, image) in taskGroup {
                    self?.state.wallets[index].imageState = .content(image)
                }
            }
        }
    }

    private func loadBalances(for userWallets: [any UserWalletModel]) {
        userWallets
            .enumerated()
            .forEach { index, userWallet in
                guard !userWallet.isUserWalletLocked else {
                    state.wallets[index].description.balanceState = .loaded(text: Localization.commonLocked)
                    return
                }

                userWallet.totalBalancePublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] balanceState in
                        self?.updateWalletBalance(index, balanceState: balanceState)
                    }
                    .store(in: &cancellables)
            }
    }
}

// MARK: - View events handling

extension WalletConnectWalletSelectorViewModel {
    func handle(viewEvent: WalletConnectWalletSelectorViewEvent) {
        switch viewEvent {
        case .navigationBackButtonTapped:
            backAction()

        case .selectedUserWalletUpdated(let selectedUserWallet):
            updateSelectedUserWallet(selectedUserWallet)

            Task {
                let extraDelay = 0.2
                try await Task.sleep(seconds: self.selectionAnimationDuration + extraDelay)
                self.userWalletSelectedAction(selectedUserWallet)
            }
        }
    }
}

// MARK: - View state updates and mapping

extension WalletConnectWalletSelectorViewModel {
    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        let updatedWallets = state.wallets.map {
            WalletConnectWalletSelectorViewState.UserWallet(
                domainModel: $0.domainModel,
                imageState: $0.imageState,
                description: $0.description,
                isSelected: $0.id == selectedUserWallet.userWalletId
            )
        }

        state.wallets = updatedWallets
    }

    func updateWalletBalance(_ walletIndex: Int, balanceState: TotalBalanceState) {
        state.wallets[walletIndex].description.balanceState = balanceStateBuilder.buildTotalBalance(state: balanceState)
    }
}

private extension WalletConnectWalletSelectorViewState {
    static func loading(userWallets: [any UserWalletModel], selectedWallet: some UserWalletModel) -> WalletConnectWalletSelectorViewState {
        WalletConnectWalletSelectorViewState(
            wallets: userWallets.map { userWallet in
                UserWallet(
                    domainModel: userWallet,
                    imageState: .loading,
                    description: .init(
                        tokensCount: "\(userWallet.userTokenListManager.userTokens.count) tokens",
                        balanceState: .loading(cached: nil)
                    ),
                    isSelected: userWallet.userWalletId == selectedWallet.userWalletId
                )
            }
        )
    }
}
