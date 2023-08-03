//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var sections: [MultiWalletTokenItemsSection] = []

    private let userWalletModel: UserWalletModel

    // MARK: - Dependencies

    private unowned let coordinator: MultiWalletMainContentRoutable
    private var sectionsProvider: TokenListInfoProvider

    private var tokenSyncSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        coordinator: MultiWalletMainContentRoutable,
        sectionsProvider: TokenListInfoProvider
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.sectionsProvider = sectionsProvider

        bind()
        subscribeToTokenListUpdatesIfNeeded()
    }

    private func bind() {
        sectionsProvider.sectionsPublisher
            .map(convertToSections(_:))
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func subscribeToTokenListUpdatesIfNeeded() {
        if !userWalletModel.userTokenListManager.userTokens.isEmpty || userWalletModel.didPerformInitialTokenSync {
            isLoadingTokenList = false
            return
        }

        tokenSyncSubscription = userWalletModel.didPerformInitialTokenSyncPublisher
            .sink(receiveValue: { [weak self] isTokenSyncPerformed in
                guard isTokenSyncPerformed else {
                    return
                }

                self?.updateTokenListLoadingState()
            })
    }

    private func updateTokenListLoadingState() {
        isLoadingTokenList = false
        tokenSyncSubscription = nil
    }

    private func convertToSections(_ sections: [TokenListSectionInfo]) -> [MultiWalletTokenItemsSection] {
        MultiWalletTokenItemsSectionFactory()
            .makeSections(from: sections, tapAction: tokenItemTapped(_:))
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return
        }

        coordinator.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }
}
