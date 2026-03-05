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
import TangemFoundation
import TangemUI

@available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
@MainActor
final class WalletConnectWalletSelectorViewModel: ObservableObject {
    private let backAction: () -> Void
    private let userWalletSelectedAction: (UserWalletModel) -> Void
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator

    private var selectedUserWallet: any UserWalletModel

    private let balanceStateBuilder: LoadableBalanceViewStateBuilder

    private var walletSelectionTask: Task<Void, Never>?
    private var walletImagesLoadingTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable>

    /// 0.3
    static let selectionAnimationDuration: TimeInterval = 0.3

    @Published private(set) var state: WalletConnectWalletSelectorViewState

    init(
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        hapticFeedbackGenerator: some WalletConnectHapticFeedbackGenerator,
        backAction: @escaping () -> Void,
        userWalletSelectedAction: @escaping (UserWalletModel) -> Void
    ) {
        self.backAction = backAction
        self.userWalletSelectedAction = userWalletSelectedAction
        self.hapticFeedbackGenerator = hapticFeedbackGenerator
        self.selectedUserWallet = selectedUserWallet

        state = .loading(userWallets: userWallets, selectedWallet: selectedUserWallet)

        balanceStateBuilder = LoadableBalanceViewStateBuilder()
        cancellables = []

        loadImages(for: userWallets)
        loadBalances(for: userWallets)
    }

    deinit {
        walletSelectionTask?.cancel()
        walletImagesLoadingTask?.cancel()
    }

    private func loadImages(for userWallets: [any UserWalletModel]) {
        walletImagesLoadingTask = Task { [weak self] in
            await withTaskGroup(of: (Int, SwiftUI.Image).self) { taskGroup in
                for (index, userWallet) in userWallets.enumerated() {
                    taskGroup.addTask {
                        let image = await userWallet.walletImageProvider.loadSmallImage().image
                        return (index, image)
                    }
                }

                for await (index, image) in taskGroup {
                    self?.state.wallets[index].imageState = .content(image)
                }
            }

            self?.walletImagesLoadingTask = nil
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
            handleSelectedUserWalletUpdated(selectedUserWallet)
        }
    }

    private func handleSelectedUserWalletUpdated(_ selectedUserWallet: some UserWalletModel) {
        let walletSelectionTaskIsRunning = walletSelectionTask != nil
        let differentWalletSelected = self.selectedUserWallet.userWalletId != selectedUserWallet.userWalletId

        updateSelectedUserWallet(selectedUserWallet)
        hapticFeedbackGenerator.selectionChanged()

        guard differentWalletSelected else {
            if !walletSelectionTaskIsRunning {
                userWalletSelectedAction(selectedUserWallet)
            }

            return
        }

        walletSelectionTask?.cancel()
        walletSelectionTask = Task { [weak self] in
            let extraDelay = 0.1
            let durationInSeconds = Self.selectionAnimationDuration + extraDelay

            try? await Task.sleep(nanoseconds: UInt64(durationInSeconds * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }

            self?.userWalletSelectedAction(selectedUserWallet)
            self?.walletSelectionTask = nil
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

        self.selectedUserWallet = selectedUserWallet
        state.wallets = updatedWallets
    }

    private func updateWalletBalance(_ walletIndex: Int, balanceState: TotalBalanceState) {
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
                        // accounts_fixes_needed_none
                        tokensCount: Localization.commonTokensCount(userWallet.walletModelsManager.walletModels.filter { $0.isMainToken }.count),
                        balanceState: .loading(cached: nil)
                    ),
                    isSelected: userWallet.userWalletId == selectedWallet.userWalletId
                )
            }
        )
    }
}
