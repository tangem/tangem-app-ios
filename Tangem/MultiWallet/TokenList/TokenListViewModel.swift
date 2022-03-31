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
    @Published var error: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []
    @Published var filteredData: [CurrencyViewModel] = []
    
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
    
    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }
    
    private let mode: Mode
    private var data: [CurrencyViewModel] = []
    private var isTestnet: Bool { cardModel?.isTestnet ?? false }
    private var bag = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable? = nil
    
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
        
        enteredSearchText
            .dropFirst()
            .sink { [unowned self] string in
                self.startSearch(with: string)
            }
            .store(in: &bag)
    }
    
    func showCustomTokenView() {
        navigation.mainToCustomToken = true
    }
    func saveChanges() {
        guard let cardModel = cardModel else {
            return
        }
        
        isSaving = true
        
        cardModel.manageTokenItems(add: pendingAdd, remove: pendingRemove) {[weak self] result in
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
        DispatchQueue.main.async {
            self.getData()
        }
    }
    
    func onDissapear() {
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.data = []
            self.enteredSearchText.value = ""
        }
    }
    
    private func startSearch(with searchText: String) {
        if searchText.isEmpty {
            filteredData = data
            return
        }
        
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
            })
    }
    
    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let cardModel = self.cardModel else {
            return false
        }
        
        if let walletManager = cardModel.walletModels?.first(where: { $0.wallet.blockchain == tokenItem.blockchain })?.walletManager {
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
        
        return cardModel.canManage(amountType: tokenItem.amountType, blockchain: tokenItem.blockchain)
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
        let isTestnet = cardModel?.cardInfo.isTestnet ?? false
        let currencies = (try? SupportedTokenItems().loadCurrencies(isTestnet: isTestnet)) ?? []
        
        let supportedCurves = cardModel?.cardInfo.card.walletCurves ?? EllipticCurve.allCases
        let fwVersion = cardModel?.cardInfo.card.firmwareVersion.doubleValue
        let isSupportSolanaTokens = fwVersion.map { $0 >= 4.52 } ?? true //[REDACTED_TODO_COMMENT]
        
        self.data = currencies.compactMap { currency in
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
                          isReadonly: isReadonlyMode,
                          isDisabled: !canManage(item),
                          isSelected: bindSelection(item),
                          position: .init(with: index, total: totalItems))
            }
            
            return .init(with: currency, items: currencyItems)
        }
        
        self.filteredData = data
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
