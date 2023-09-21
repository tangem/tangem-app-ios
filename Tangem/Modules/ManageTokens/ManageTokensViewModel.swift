//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ManageTokensViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var tokenViewModels: [ManageTokensItemViewModel] = []
    @Published var isLoading: Bool = true
    @Published var alert: AlertBinder?
    @Published var showToast: Bool = false

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()

    private unowned let coordinator: ManageTokensRoutable

    private var percentFormatter = PercentFormatter()
    private var balanceFormatter = BalanceFormatter()

    init(coordinator: ManageTokensRoutable) {
        self.coordinator = coordinator

        bind()
    }

    func tokenListDidSave() {
        Analytics.log(.buttonSaveChanges)
    }

    func onAppear() {
        Analytics.log(.manageTokensScreenOpened)
        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
}

// MARK: - Private

private extension ManageTokensViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.tokenSearched)
                }

                self?.loader.fetch(string)
            }
            .store(in: &bag)

        $tokenViewModels
            .sink { [weak self] items in
                self?.updateQuote(by: items)
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = Set(userWalletRepository.models.map { $0.config.supportedBlockchains }.joined())
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .map { [weak self] items -> [ManageTokensItemViewModel] in
                items.compactMap { self?.mapToTokenViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.tokenViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    // MARK: - Private Implementation

    private func displayAlertAndUpdateSelection(title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk))

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

    // [REDACTED_TODO_COMMENT]
    private func actionType(for coinModel: CoinModel) -> ManageTokensItemViewModel.Action {
        let userWalletModels = userWalletRepository.models

        let isAlreadyExistToken = userWalletModels.contains(where: { userWalletModel in
            coinModel.items.contains(where: { tokenItem in
                userWalletModel.userTokensManager.contains(tokenItem, derivationPath: nil)

            })
        })

        return isAlreadyExistToken ? .edit : .add
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        ManageTokensItemViewModel(
            coinModel: coinModel,
            action: actionType(for: coinModel),
            didTapAction: handle(action:with:)
        )
    }

    private func handle(action: ManageTokensItemViewModel.Action, with coinModel: CoinModel) {
        switch action {
        case .info:
            coordinator.openInfoTokenModule(with: coinModel)
        case .add:
            coordinator.openAddTokenModule(with: coinModel)
        case .edit:
            coordinator.openEditTokenModule(with: coinModel)
        }
    }

    private func updateQuote(by items: [ManageTokensItemViewModel]) {
        tokenQuotesRepository
            .loadQuotes(coinIds: items.filter { $0.priceChangeState == .loading }.map { $0.id })
            .receive(on: DispatchQueue.main)
            .receiveCompletion { _ in
                items.forEach {
                    $0.updateQuote()
                }
            }
            .store(in: &bag)
    }
}
