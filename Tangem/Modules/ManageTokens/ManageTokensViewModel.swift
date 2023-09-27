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

    private unowned let coordinator: ManageTokensRoutable

    private lazy var loader = setupListDataLoader()
    private let percentFormatter = PercentFormatter()
    private let balanceFormatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()
    private var loadQuotesSubscribtion: AnyCancellable?

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
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = Set(userWalletRepository.models.map { $0.config.supportedBlockchains }.joined())
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                let alreadyUpdateQuoteCoinIds = tokenViewModels.filter {
                    $0.priceChangeState != .loading || $0.priceChangeState != .noData
                }.map { $0.id }

                let itemsShouldLoadQuote = items.filter {
                    !alreadyUpdateQuoteCoinIds.contains($0.id)
                }.map { $0.id }

                tokenViewModels = items.compactMap { self.mapToTokenViewModel(coinModel: $0) }
                updateQuote(by: itemsShouldLoadQuote)
            })
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

    private func displayAlert(title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk))

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

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

    private func updateQuote(by coinIds: [String]) {
        loadQuotesSubscribtion = tokenQuotesRepository
            .loadQuotes(coinIds: coinIds)
            .sink()
    }

    private func handle(action: ManageTokensItemViewModel.Action, with coinModel: CoinModel) {
        switch action {
        case .info:
            // [REDACTED_TODO_COMMENT]
            break
        case .add, .edit:
            coordinator.openTokenSelectorModule(with: coinModel.items)
        }
    }
}
