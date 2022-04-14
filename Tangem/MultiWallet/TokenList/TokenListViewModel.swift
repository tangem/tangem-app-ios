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
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    var enteredSearchText = CurrentValueSubject<String, Never>("") //I can't use @Published here, because of swiftui redraw perfomance drop
    
    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var error: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []
    @Published var showToast: Bool = false
    
    lazy var loader: ListDataLoader = {
        let isTestnet = mode.cardModel?.cardInfo.isTestnet ?? false
        let loader = ListDataLoader(isTestnet: isTestnet)
        loader.delegate = self
        
        loader.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] in
                self.objectWillChange.send()
            })
            .store(in: &bag)
        
        return loader
    }()
    
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
        guard let card = mode.cardModel?.cardInfo.card else {
            return false
        }
        
        return card.settings.isHDWalletAllowed && card.derivationStyle == .legacy
    }
    
    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }
    
    private let mode: Mode
    private var bag = Set<AnyCancellable>()
    
    init(mode: Mode) {
        self.mode = mode
        
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] string in
                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }
    
    func showCustomTokenView() {
        navigation.tokensToCustomToken = true
    }
    
    func saveChanges() {
        guard let cardModel = mode.cardModel else {
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
    
    func onDissapear() {
        pendingAdd = []
        pendingRemove = []
        
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
            self.navigation.tokensToCustomToken = false //ios13 bug
        }
    }
    
    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
    
    private func showAddButton(_ tokenItem: TokenItem) -> Bool {
        switch mode {
        case .add:
            return true
        case .show:
            return false
        }
    }
    
    //MARK: - Mapping
    
    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = mode.cardModel else {
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
    
    private func canManage(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = mode.cardModel else {
            return false
        }
        
        let network = tokenItem.getDefaultBlockchainNetwork(for: cardModel.cardInfo.card.derivationStyle)
        return cardModel.canManage(amountType: tokenItem.amountType, blockchainNetwork: network)
    }
    
    private func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = self.pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = self.pendingRemove.contains(tokenItem)
        let alreadyAdded = self.isAdded(tokenItem)
        
        if isWaitingToBeRemoved {
            return false
        }
        
        return isWaitingToBeAdded || alreadyAdded
    }
    
    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
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
    
    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            self?.onSelect(isSelected, tokenItem)
        }
        
        return binding
    }
    
    private func bindCopy() -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.showToast ?? false
        } set: { [weak self] isSelected in
            self?.showToast = isSelected
        }
        
        return binding
    }
}

extension TokenListViewModel: ListDataLoaderDelegate {
    func filter(_ model: CurrencyModel) -> CurrencyModel? {
        let supportedCurves = mode.cardModel?.cardInfo.card.walletCurves ?? EllipticCurve.allCases
        let isSupportSolanaTokens = mode.cardModel?.cardInfo.card.canSupportSolanaTokens ?? true
        
        var model = model
        let filteredItems = model.items.filter { item in
            if !supportedCurves.contains(item.blockchain.curve) {
                return false
            }
            
            if !isSupportSolanaTokens, item.isToken,
               item.blockchain == .solana(testnet: true) ||
                item.blockchain == .solana(testnet: false) {
                return false
            }
            
            return true
        }
        
        if filteredItems.isEmpty {
            return nil
        }
        
        model.items = filteredItems
        return model
    }
    
    func map(_ model: CurrencyModel) -> CurrencyViewModel {
        let currencyItems: [CurrencyItemViewModel] = model.items.enumerated().map { (index, item) in
                .init(tokenItem: item,
                      isReadonly: self.isReadonlyMode,
                      isDisabled: !self.canManage(item),
                      isSelected: self.bindSelection(item),
                      isCopied: self.bindCopy(),
                      position: .init(with: index, total: model.items.count))
        }
        
        return CurrencyViewModel(with: model, items: currencyItems)
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
