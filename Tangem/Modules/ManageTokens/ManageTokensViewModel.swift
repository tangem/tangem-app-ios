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
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [LegacyCoinViewModel] = []

    @Published var tokenViewModels: [ManageTokensItemViewModel] = []

    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []
    @Published var showToast: Bool = false

    var titleKey: String {
        return Localization.addTokensTitle
    }

    var shouldShowAlert: Bool {
        settings.shouldShowLegacyDerivationAlert
    }

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: ManageTokensRoutable

    private let settings: LegacyManageTokensSettings
    private let userTokensManager: UserTokensManager
    private let tokenQuotesRepository: TokenQuotesRepository

    private var percentFormatter = PercentFormatter()

    init(
        settings: LegacyManageTokensSettings,
        userTokensManager: UserTokensManager,
        tokenQuotesRepository: TokenQuotesRepository,
        coordinator: ManageTokensRoutable
    ) {
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.tokenQuotesRepository = tokenQuotesRepository
        self.coordinator = coordinator

        bind()
    }

    func saveChanges() {
        isSaving = true

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false

                switch result {
                case .success:
                    self?.tokenListDidSave()
                case .failure(let error):
                    if error.isUserCancelled {
                        return
                    }

                    self?.alert = error.alertBinder
                }
            }
        }
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
            self.pendingAdd = []
            self.pendingRemove = []
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

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.contains(tokenItem, derivationPath: nil)
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.canRemove(tokenItem, derivationPath: nil)
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = pendingRemove.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        if isWaitingToBeRemoved {
            return false
        }

        return isWaitingToBeAdded || alreadyAdded
    }

    func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
        if selected,
           case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedMessage
            )

            return
        }

        if selected, !settings.existingCurves.contains(tokenItem.blockchain.curve) {
            displayAlertAndUpdateSelection(
                for: tokenItem,
                title: Localization.commonAttention,
                message: Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
            )

            return
        }

        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        let alreadyAdded = isAdded(tokenItem)

        if alreadyAdded {
            if selected {
                pendingRemove.remove(tokenItem)
            } else {
                pendingRemove.append(tokenItem)
            }
        } else {
            if selected {
                pendingAdd.append(tokenItem)
            } else {
                pendingAdd.remove(tokenItem)
            }
        }
    }

    func updateSelection(_ tokenItem: TokenItem) {
        for item in coinViewModels {
            for itemItem in item.items {
                if itemItem.tokenItem == tokenItem {
                    itemItem.updateSelection(with: bindSelection(tokenItem))
                }
            }
        }
    }

    func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            self?.showWarningDeleteAlertIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
        }

        return binding
    }

    func bindCopy() -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.showToast ?? false
        } set: { [weak self] isSelected in
            self?.showToast = isSelected
        }

        return binding
    }

    // [REDACTED_TODO_COMMENT]
    func mapToCoinViewModel(coinModel: CoinModel) -> LegacyCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            LegacyCoinItemViewModel(
                tokenItem: item,
                isReadonly: false,
                isSelected: bindSelection(item),
                isCopied: bindCopy(),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return LegacyCoinViewModel(with: coinModel, items: currencyItems)
    }

    func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel? {
        var quote: TokenQuote?

        if let coinModelBlockchain = coinModel.blockchain {
            quote = tokenQuotesRepository.quote(for: .blockchain(coinModelBlockchain))
        }

        return ManageTokensItemViewModel(
            imageURL: TokenIconURLBuilder().iconURL(id: coinModel.id, size: .large),
            name: coinModel.name,
            symbol: coinModel.symbol,
            price: quote?.price.description ?? "",
            priceChange: getPriceChange(by: quote),
            priceHistory: nil,
            action: actionType(for: coinModel),
            didTapAction: handle(action:)
        )
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard !isSelected,
              !pendingAdd.contains(tokenItem),
              isTokenAvailable(tokenItem) else {
            onSelect(isSelected, tokenItem)
            return
        }

        if canRemove(tokenItem) {
            let title = Localization.tokenDetailsHideAlertTitle(tokenItem.currencySymbol)

            let cancelAction = { [unowned self] in
                updateSelection(tokenItem)
            }

            let hideAction = { [unowned self] in
                onSelect(isSelected, tokenItem)
            }

            alert = AlertBinder(alert:
                Alert(
                    title: Text(title),
                    message: Text(Localization.tokenDetailsHideAlertMessage),
                    primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                    secondaryButton: .cancel(cancelAction)
                )
            )
        } else {
            let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.blockchain.currencySymbol)

            let message = Localization.tokenDetailsUnableHideAlertMessage(
                tokenItem.blockchain.currencySymbol,
                tokenItem.blockchain.displayName
            )

            alert = AlertBinder(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text(Localization.commonOk), action: {
                    self.updateSelection(tokenItem)
                })
            ))
        }
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
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

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    // MARK: - Private Implementation

    private func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

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

    private func handle(action: ManageTokensItemViewModel.Action) {
        switch action {
        case .add:
            coordinator.openAddTokenModule()
        case .edit:
            coordinator.openEditTokenModule()
        case .info:
            coordinator.openInfoTokenModule()
        }
    }

    private func getPriceChange(by quote: TokenQuote?) -> TokenPriceChangeView.State {
        guard let quote = quote else {
            return .noData
        }

        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        return .loaded(signType: signType, text: percent)
    }
}
