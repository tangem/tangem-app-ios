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

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var tokenViewModels: [ManageTokensItemViewModel] = []

    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var alert: AlertBinder?
    @Published var showToast: Bool = false

    // MARK: - Properties

    var titleKey: String {
        return Localization.addTokensTitle
    }

    var shouldShowAlert: Bool {
        settings.shouldShowLegacyDerivationAlert
    }

    var isSaveDisabled: Bool {
        true
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: ManageTokensRoutable

    private let settings: LegacyManageTokensSettings
    private let userTokensManager: UserTokensManager

    private var percentFormatter = PercentFormatter()
    private var balanceFormatter = BalanceFormatter()

    init(
        settings: LegacyManageTokensSettings,
        userTokensManager: UserTokensManager,
        coordinator: ManageTokensRoutable
    ) {
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.coordinator = coordinator

        bind()
    }

    func saveChanges() {
        isSaving = true
    }

    func tokenListDidSave() {
        Analytics.log(.buttonSaveChanges)
        closeModule()
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

// MARK: - Navigation

extension ManageTokensViewModel {
    func closeModule() {
//        coordinator.closeModule()
    }

    func openAddCustom() {
        Analytics.log(.buttonCustomToken)
        coordinator.openAddCustomTokenModule(settings: settings, userTokensManager: userTokensManager)
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

    func showAddButton(_ tokenItem: TokenItem) -> Bool {
        return true
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = settings.supportedBlockchains
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

    func onHandleAddTokenAction(_ tokenItem: TokenItem) {
        if case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedMessage
            )

            return
        }

        if !settings.existingCurves.contains(tokenItem.blockchain.curve) {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
            )

            return
        }

        coordinator.openAddTokenModule(with: tokenItem)
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard isTokenAvailable(tokenItem) else {
            return
        }

        return
    }

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    // MARK: - Private Implementation

    private func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk))

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

    // [REDACTED_TODO_COMMENT]
    private func actionType(for coinModel: CoinModel) -> ManageTokensItemViewModel.Action {
        if coinModel.items.contains(where: { tokenItem in
            userTokensManager.contains(tokenItem, derivationPath: nil)
        }) {
            return .edit
        } else {
            return .add
        }
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        let cachePriceChangeValue = getCachePriceWithChangeState(by: coinModel.id)

        return ManageTokensItemViewModel(
            id: coinModel.id,
            imageURL: TokenIconURLBuilder().iconURL(id: coinModel.id, size: .large),
            name: coinModel.name,
            symbol: coinModel.symbol,
            priceValue: balanceFormatter.formatFiatBalance(cachePriceChangeValue.0),
            priceChangeState: cachePriceChangeValue.1,
            action: actionType(for: coinModel),
            didTapAction: handle(action:with:)
        )
    }

    private func handle(action: ManageTokensItemViewModel.Action, with id: ManageTokensItemViewModel.ID) {}

    private func updateQuote(by items: [ManageTokensItemViewModel]) {
        tokenQuotesRepository
            .loadQuotes(coinIds: items.filter { $0.priceChangeState == .loading }.map { $0.id })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { quotes in
                print(quotes.count)

                quotes.forEach { [weak self] quote in
                    guard let self = self, let itemViewModel = items.first(where: { $0.id == quote.currencyId }) else { return }
                    itemViewModel.priceChangeState = getPriceChangeState(by: quote)
                    itemViewModel.priceValue = balanceFormatter.formatFiatBalance(quote.price)
                }
            })
            .store(in: &bag)
    }

    private func getCachePriceWithChangeState(by currencyId: String) -> (Decimal?, TokenPriceChangeView.State) {
        guard let quote = tokenQuotesRepository.quote(for: currencyId) else {
            return (nil, .loading)
        }

        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        return (nil, .loaded(signType: signType, text: percent))
    }

    private func getPriceChangeState(by quote: TokenQuote) -> TokenPriceChangeView.State {
        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        return .loaded(signType: signType, text: percent)
    }

    private func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        if case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            return false
        }

        if !settings.existingCurves.contains(tokenItem.blockchain.curve) {
            return false
        }

        return true
    }
}
