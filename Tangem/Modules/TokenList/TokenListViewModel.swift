//
//  TokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk
import SwiftUI

class TokenListViewModel: ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [CoinViewModel] = []

    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []
    @Published var showToast: Bool = false

    var titleKey: LocalizedStringKey {
        switch mode {
        case .add:
            return "add_tokens_title"
        case .show:
            return "search_tokens_title"
        }
    }

    var isReadonlyMode: Bool {
        switch mode {
        case .add:
            return false
        case .show:
            return true
        }
    }

    var shouldShowAlert: Bool {
        cardModel?.shouldShowLegacyDerivationAlert ?? false
    }

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    var cardModel: CardViewModel? {
        mode.cardModel
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private let mode: Mode
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: TokenListRoutable

    init(mode: Mode, coordinator: TokenListRoutable) {
        self.mode = mode
        self.coordinator = coordinator

        bind()
    }

    func saveChanges() {
        guard let cardModel = cardModel,
              let userWalletModel = cardModel.userWalletModel else {
            closeModule()
            return
        }

        var alreadySaved = userWalletModel.userTokenListManager.getEntriesFromRepository()

        DispatchQueue.global().async {
            self.update(cardModel: cardModel, entries: &alreadySaved)
            self.updateStorage(cardModel: cardModel, entries: alreadySaved)
        }
    }

    func updateStorage(cardModel: CardViewModel, entries: [StorageEntry]) {
        DispatchQueue.main.async {
            self.isSaving = true
        }

        cardModel.update(entries: entries) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false

                switch result {
                case .success:
                    self?.tokenListDidSave()
                case .failure(let error):
                    if let sdkError = error as? TangemSdkError, sdkError.isUserCancelled {
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
extension TokenListViewModel {
    func closeModule() {
        coordinator.closeModule()
    }

    func openAddCustom() {
        if let cardModel = self.cardModel {
            Analytics.log(.buttonCustomToken)
            coordinator.openAddCustom(for: cardModel)
        }
    }
}

// MARK: - Private

private extension TokenListViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func showAddButton(_ tokenItem: TokenItem) -> Bool {
        switch mode {
        case .add:
            return true
        case .show:
            return false
        }
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = cardModel?.supportedBlockchains ?? Blockchain.supportedBlockchains
        let networkIds = supportedBlockchains.map { $0.networkId }
        let loader = ListDataLoader(networkIds: networkIds, exchangeable: false)

        loader.$items
            .map { [unowned self] items -> [CoinViewModel] in
                items.compactMap { self.mapToCoinViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.coinViewModels, on: self)
            .store(in: &bag)

        return loader
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = cardModel else {
            return false
        }

        let network = cardModel.getBlockchainNetwork(for: tokenItem.blockchain, derivationPath: nil)
        if let walletManager = cardModel.walletModels.first(where: { $0.blockchainNetwork == network })?.walletManager {
            if let token = tokenItem.token {
                return walletManager.cardTokens.contains(token)
            }

            return true
        }

        return false
    }

    func canManage(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = cardModel else {
            return false
        }

        let network = cardModel.getBlockchainNetwork(for: tokenItem.blockchain, derivationPath: nil)
        return cardModel.canManage(amountType: tokenItem.amountType, blockchainNetwork: network)
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = self.pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = self.pendingRemove.contains(tokenItem)
        let alreadyAdded = self.isAdded(tokenItem)

        if isWaitingToBeRemoved {
            return false
        }

        return isWaitingToBeAdded || alreadyAdded
    }

    func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
        guard let cardModel = cardModel else {
            return
        }
        if selected,
           case let .token(_, blockchain) = tokenItem,
           case .solana = blockchain,
           !cardModel.longHashesSupported
        {
            let okButton = Alert.Button.default(Text("common_ok".localized)) {
                self.updateSelection(tokenItem)
            }

            alert = AlertBinder(alert: Alert(title: Text("common_attention".localized),
                                             message: Text("alert_manage_tokens_unsupported_message".localized),
                                             dismissButton: okButton))

            return
        }
        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        let alreadyAdded = isAdded(tokenItem)

        let network = cardModel.getBlockchainNetwork(for: tokenItem.blockchain, derivationPath: nil)
        let token = TokenItem.blockchain(network.blockchain)

        if alreadyAdded {
            if selected {
                pendingRemove.remove(tokenItem)
                if pendingRemove.contains(token) {
                    pendingRemove.remove(token)
                    updateSelection(token)
                }
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

    func mapToCoinViewModel(coinModel: CoinModel) -> CoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { (index, item) in
            CoinItemViewModel(tokenItem: item,
                              isReadonly: isReadonlyMode,
                              isSelected: bindSelection(item),
                              isCopied: bindCopy(),
                              position: .init(with: index, total: coinModel.items.count))
        }

        return CoinViewModel(with: coinModel, items: currencyItems)
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard !isSelected,
              !self.pendingAdd.contains(tokenItem),
              self.isTokenAvailable(tokenItem) else {
            self.onSelect(isSelected, tokenItem)
            return
        }
        if canManage(tokenItem) || canRemove(tokenItem: tokenItem) {
            let title = "token_details_hide_alert_title".localized(tokenItem.blockchain.currencySymbol)

            let cancelAction = { [unowned self] in
                self.updateSelection(tokenItem)
            }

            let hideAction = { [unowned self] in
                self.onSelect(isSelected, tokenItem)
            }

            alert = AlertBinder(alert:
                Alert(title: Text(title),
                      message: Text("token_details_hide_alert_message".localized),
                      primaryButton: .destructive(Text("token_details_hide_alert_hide"), action: hideAction),
                      secondaryButton: .cancel(cancelAction))
            )
        } else {
            guard let cardModel = cardModel else { return }

            let network = cardModel.getBlockchainNetwork(for: tokenItem.blockchain, derivationPath: nil)

            guard let walletModel = cardModel.walletModels.first(where: { $0.blockchainNetwork == network }) else {
                return
            }

            let title = "token_details_unable_hide_alert_title".localized(tokenItem.blockchain.currencySymbol)

            let message = "token_details_unable_hide_alert_message".localized([
                tokenItem.blockchain.currencySymbol,
                walletModel.blockchainNetwork.blockchain.displayName,
            ])

            alert = AlertBinder(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text("common_ok"), action: {
                    self.updateSelection(tokenItem)
                })
            ))
        }
    }

    private func canRemove(tokenItem: TokenItem) -> Bool {
        guard let cardModel = cardModel else { return false }

        let network = cardModel.getBlockchainNetwork(for: tokenItem.blockchain, derivationPath: nil)

        guard let walletModel = cardModel.walletModels.first(where: { $0.blockchainNetwork == network })  else {
            return false
        }


        let cardTokens: [TokenItem] = walletModel
            .walletManager
            .cardTokens
            .map { token in
                TokenItem.token(token, network.blockchain)
            }
            .filter({ !pendingRemove.contains($0) })

        return cardTokens.isEmpty
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        if case let .token(_, blockchain) = tokenItem,
           case .solana = blockchain,
           let cardModel = cardModel,
           !cardModel.longHashesSupported
        {
            return false
        }
        return true
    }

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        let state: Analytics.ParameterValue = tokenIsSelected ? .on : .off
        Analytics.log(.tokenSwitcherChanged, params: [
            .state: state.rawValue,
        ])
    }

    func update(cardModel: CardViewModel, entries: inout [StorageEntry]) {
        pendingRemove.forEach { tokenItem in
            switch tokenItem {
            case let .blockchain(blockchain):
                entries.removeAll { $0.blockchainNetwork.blockchain.id == blockchain.id }
            case let .token(token, blockchain):
                if let index = entries.firstIndex(where: { $0.blockchainNetwork.blockchain.id == blockchain.id }) {
                    entries[index].tokens.removeAll { $0.id == token.id }
                }
            }
        }

        pendingAdd.forEach { tokenItem in
            switch tokenItem {
            case let .blockchain(blockchain):
                let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)
                if !entries.contains(where: { $0.blockchainNetwork == network }) {
                    let entry = StorageEntry(blockchainNetwork: network, tokens: [])
                    entries.append(entry)
                }
            case let .token(token, blockchain):
                let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)

                if let entry = entries.firstIndex(where: { $0.blockchainNetwork == network }) {
                    entries[entry].tokens.append(token)
                } else {
                    let entry = StorageEntry(blockchainNetwork: network, token: token)
                    entries.append(entry)
                }
            }
        }
    }
}

extension TokenListViewModel {
    enum Mode {
        case add(cardModel: CardViewModel)
        case show

        var id: String {
            switch self {
            case .add:
                return "add"
            case .show:
                return "show"
            }
        }

        var cardModel: CardViewModel? {
            switch self {
            case .add(let cardModel):
                return cardModel
            case .show:
                return nil
            }
        }
    }
}
