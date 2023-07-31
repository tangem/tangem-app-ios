//
//  MainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var pages: [MainCardPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false

    // MARK: - Dependencies

    private let userWalletRepository: UserWalletRepository
    private var coordinator: MainRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        userWalletRepository: UserWalletRepository,
        mainCardPageBuilderFactory: MainCardPageBuilderFactory = CommonMainCardPageBuilderFactory()
    ) {
        self.coordinator = coordinator
        self.userWalletRepository = userWalletRepository

        pages = mainCardPageBuilderFactory.createPages(from: userWalletRepository.models)
        setupHorizontalScrollAvailability()
    }

    convenience init(
        userWalletModel: UserWalletModel,
        coordinator: MainRoutable,
        userWalletRepository: UserWalletRepository,
        mainCardPageBuilderFactory: MainCardPageBuilderFactory = CommonMainCardPageBuilderFactory()
    ) {
        self.init(coordinator: coordinator, userWalletRepository: userWalletRepository, mainCardPageBuilderFactory: mainCardPageBuilderFactory)

        if let selectedIndex = pages.firstIndex(where: { $0.id == userWalletModel.userWalletId.stringValue }) {
            selectedCardIndex = selectedIndex
        }
    }

    // MARK: - Internal functions

    func scanNewCard() {}

    func openDetails() {
        // [REDACTED_TODO_COMMENT]
        guard let cardViewModel = userWalletRepository.models[selectedCardIndex] as? CardViewModel else {
            log("Failed to cast user wallet model to CardViewModel")
            return
        }

        coordinator?.openDetails(for: cardViewModel)
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        isHorizontalScrollDisabled = true
        let completion = { [weak self] in
            self?.setupHorizontalScrollAvailability()
            completionHandler()
        }
        let page = pages[selectedCardIndex]
        let model = userWalletRepository.models[selectedCardIndex]

        switch page {
        case .singleWallet:
            model.walletModelsManager.updateAll(silent: false, completion: completion)
        case .multiWallet:
            model.userTokenListManager.updateLocalRepositoryFromServer { _ in
                model.walletModelsManager.updateAll(silent: true, completion: completion)
            }
        }
    }

    // MARK: - Private functions

    private func setupHorizontalScrollAvailability() {
        isHorizontalScrollDisabled = pages.count <= 1
    }

    private func bind() {}

    private func log(_ message: String) {
        AppLog.shared.debug("[Main V2] \(message)")
    }
}
