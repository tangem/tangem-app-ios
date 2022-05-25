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

class TokenListViewModel: ViewModel, ObservableObject {
    @Injected(\.negativeFeedbackDataProvider) var dataCollector: NegativeFeedbackDataProvider
    @Injected(\.coinsService) var coinsService: CoinsService
    
    //I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")
    
    @Published var coinViewModels: [CoinViewModel] = []
    
    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var error: AlertBinder?
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
        guard let card = cardModel?.cardInfo.card else {
            return false
        }
        
        return card.settings.isHDWalletAllowed && card.derivationStyle == .legacy
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
    
    init(mode: Mode) {
        self.mode = mode
        
        super.init()
        
        bind()
    }
    
    func showCustomTokenView() {
        navigation.tokensToCustomToken = true
    }
    
    func saveChanges() {
        guard let cardModel = cardModel else {
            return
        }
        
        isSaving = true
        
        let cardDerivationStyle = cardModel.cardInfo.card.derivationStyle
        let itemsToRemove = pendingRemove.map {
            ($0.amountType, $0.getDefaultBlockchainNetwork(for: cardDerivationStyle))
        }
        
        cardModel.remove(items: itemsToRemove)
        
        let itemsToAdd = pendingAdd.map {
            ($0.amountType, $0.getDefaultBlockchainNetwork(for: cardDerivationStyle))
        }
        
        cardModel.add(items: itemsToAdd) {[weak self] result in
            self?.isSaving = false
            
            switch result {
            case .success:
                self?.navigation.mainToAddTokens = false
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {} else {
                    self?.error = error.alertBinder
                }
            }
        }
    }
    
    func onAppear() {
        loader.reset(enteredSearchText.value)
    }
    
    func onDisappear() {
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.enteredSearchText.value = ""
            self.navigation.tokensToCustomToken = false //ios13 bug
        }
    }
    
    func fetch() {
        loader.fetch(enteredSearchText.value)
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
        let isTestnet = cardModel?.cardInfo.isTestnet ?? false
        let loader = ListDataLoader(isTestnet: isTestnet, coinsService: coinsService)
        loader.delegate = self
        
        loader.$items
            .map { [unowned self] items -> [CoinViewModel] in
                items.compactMap { self.mapToCoinViewModel(coinModel: $0) }
            }
            .weakAssign(to: \.coinViewModels, on: self)
            .store(in: &bag)
        
        return loader
    }
    
    func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = cardModel else {
            return false
        }
        
        let network = tokenItem.getDefaultBlockchainNetwork(for: cardModel.cardInfo.card.derivationStyle)
        if let walletManager = cardModel.walletModels?.first(where: { $0.blockchainNetwork == network })?.walletManager {
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
        
        let network = tokenItem.getDefaultBlockchainNetwork(for: cardModel.cardInfo.card.derivationStyle)
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
        if selected,
           case let .token(_, blockchain) = tokenItem,
           case .solana = blockchain,
           let cardModel = cardModel,
           !cardModel.cardInfo.card.canSupportSolanaTokens
        {
            let okButton = Alert.Button.default(Text("common_ok".localized)) {
                self.updateSelection(tokenItem)
            }
            
            error = AlertBinder(alert: Alert(title: Text("common_attention".localized),
                                             message: Text("alert_manage_tokens_unsupported_message".localized),
                                             dismissButton: okButton))
            
            return
        }
        
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
            self?.onSelect(isSelected, tokenItem)
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
                              isDisabled: !canManage(item),
                              isSelected: bindSelection(item),
                              isCopied: bindCopy(),
                              position: .init(with: index, total: coinModel.items.count))
        }
        
        return CoinViewModel(with: coinModel, items: currencyItems)
    }
}

// MARK: - ListDataLoaderDelegate

extension TokenListViewModel: ListDataLoaderDelegate {
    func filter(_ model: CoinModel) -> CoinModel? {
        if let card = cardModel?.cardInfo.card {
            return model.makeFiltered(with: card)
        }
        
        return model
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
