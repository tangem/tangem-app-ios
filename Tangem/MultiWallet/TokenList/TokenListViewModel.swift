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
    @Published var filteredData: [CurrencyViewModel] = []
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
        guard let cardModel = self.cardModel else {
            return false
        }
        
        return cardModel.cardInfo.card.derivationStyle == .legacy
    }
    
    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }
    
    private let mode: Mode
    private var data: [CurrencyViewModel] = []
    private var isTestnet: Bool { cardModel?.isTestnet ?? false }
    private var bag = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable? = nil
    private var loadCancellable: AnyCancellable? = nil
    
    private var cardModel: CardViewModel? {
        switch mode {
        case .add(let cardModel):
            return cardModel
        case .show:
            return nil
        }
    }
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    func showCustomTokenView() {
        navigation.mainToCustomToken = true
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
        bind()
        self.getData()
    }
    
    func onDissapear() {
        loadCancellable?.cancel()
        searchCancellable?.cancel()
        bag.removeAll()
        
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.enteredSearchText.value = ""
            self.filteredData = []
        }
    }
    
    private func startSearch(with searchText: String) {
        if searchText.isEmpty {
            filteredData = data
            isLoading = false
            return
        }
        
        isLoading = true
        
        filteredData = []
        searchCancellable =
        Just(searchText)
            .receive(on: DispatchQueue.global(), options: nil)
            .map {[unowned self] string in
                return self.search(string)
            }
            .receive(on: DispatchQueue.main, options: nil)
            .sink(receiveValue: {[unowned self] results in
                self.filteredData = results
                self.isLoading = false
            })
    }
    
    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = self.cardModel else {
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
        guard let cardModel = cardModel else {
            return false
        }
        
        let network = tokenItem.getDefaultBlockchainNetwork(for: cardModel.cardInfo.card.derivationStyle)
        return cardModel.canManage(amountType: tokenItem.amountType, blockchainNetwork: network)
    }
    
    private func showAddButton(_ tokenItem: TokenItem) -> Bool {
        switch mode {
        case .add:
            return true
        case .show:
            return false
        }
    }
    
    private func search(_ searchText: String) -> [CurrencyViewModel] {
        let filter = searchText.lowercased()
        
        return data.filter {
            $0.name.lowercased().contains(filter)
            || $0.symbol.lowercased().contains(filter)
        }
        .sorted(by: { lhs, rhs in
            if lhs.name.lowercased() == filter
                || lhs.symbol.lowercased() == filter {
                return true
            }
            
            return false
        })
    }
    
    private func getData()  {
        isLoading = true
        
        if !data.isEmpty {
            loadCancellable = Just(data)
                .delay(for: 0.1, scheduler: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] items in
                    self.filteredData = self.data
                    self.isLoading = false
                })
            return
        }
        
        let isTestnet = cardModel?.cardInfo.isTestnet ?? false
        let itemsRepo = SupportedTokenItems()
        
        let supportedCurves = cardModel?.cardInfo.card.walletCurves ?? EllipticCurve.allCases
        let isSupportSolanaTokens = cardModel?.cardInfo.card.canSupportSolanaTokens ?? true
        
        loadCancellable = itemsRepo.loadCurrencies(isTestnet: isTestnet)
            .map {[unowned self] currencies -> [CurrencyViewModel] in
                currencies.compactMap { currency -> CurrencyViewModel? in
                    let filteredItems = currency.items.filter { item in
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
                    
                    let totalItems = filteredItems.count
                    guard totalItems > 0 else {
                        return nil
                    }
                    
                    let currencyItems: [CurrencyItemViewModel] = filteredItems.enumerated().map { (index, item) in
                            .init(tokenItem: item,
                                  isReadonly: self.isReadonlyMode,
                                  isDisabled: !self.canManage(item),
                                  isSelected: self.bindSelection(item),
                                  isCopied: self.bindCopy(),
                                  position: .init(with: index, total: totalItems))
                    }
                    
                    return CurrencyViewModel(with: currency, items: currencyItems)
                }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink {[unowned self] items in
                self.data = items
                self.filteredData = items
                self.isLoading = false
            }
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
    
    private func bind() {
        enteredSearchText
            .dropFirst()
            .sink { [unowned self] string in
                self.startSearch(with: string)
            }
            .store(in: &bag)
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
    }
}
