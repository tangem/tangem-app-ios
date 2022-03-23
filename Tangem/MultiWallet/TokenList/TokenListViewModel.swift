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
    
    var isDemoMode: Bool {
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
        print("!!! init")
        self.mode = mode
        
        enteredSearchText
            .dropFirst()
            .sink { [unowned self] string in
                self.startSearch(with: string)
            }
            .store(in: &bag)
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
        print("!!! onAppear")
        DispatchQueue.main.async {
            self.getData()
        }
    }
    
    func onDissapear() {
        print("!!! onDissapear")
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.data = []
            self.enteredSearchText.value = ""
        }
    }
    
    private func startSearch(with searchText: String) {
        print("!!! startsearch")
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
    
    private func getData()  { //[REDACTED_TODO_COMMENT]
        do {
        let isTestnet = cardModel?.cardInfo.isTestnet ?? false
        let tokens = try SupportedTokenItems().loadTokens(isTestnet: isTestnet)
        let supportedCurves = cardModel?.cardInfo.card.walletCurves ?? EllipticCurve.allCases
            
        self.data = tokens.compactMap { token in
            if token.contracts.isEmpty { //blockchain
                if let tokenBlockchain = token.blockchain {
                    if !supportedCurves.contains(tokenBlockchain.curve) {
                        return nil //unsupported curve, skipping
                    }
                    
                    let tokenItem = TokenItem.blockchain(tokenBlockchain)
                    return .init(with: token, items: [makeCurrencyItemViewModel(tokenItem)])
                } else {
                    return nil //unknown blockchain, skipping
                }
            } else { //token
                let fwVersion = cardModel?.cardInfo.card.firmwareVersion.doubleValue
                let isSupportSolanaTokens = fwVersion.map { $0 < 4.52 } ?? true //[REDACTED_TODO_COMMENT]
                //filter by curves
                let contracts = isSupportSolanaTokens ? token.contracts
                : token.contracts.filter { $0.blockchain != .solana(testnet: true) && $0.blockchain != .solana(testnet: false) }
                let blockchainTokens = contracts.map { BlockchainSdk.Token(with: token, contract: $0) }
                let filteredByCurve = blockchainTokens.filter {
                    supportedCurves.contains($0.blockchain.curve)
                }
                let tokenItems: [TokenItem] = filteredByCurve.map { .token($0) }
                let currencyItems: [CurrencyItemViewModel] = tokenItems.map { makeCurrencyItemViewModel($0) }
                
                if currencyItems.isEmpty {
                    return nil //no tokens with supported curves, skipping
                }
                
                return .init(with: token, items: currencyItems)
            }
        }
            self.filteredData = data
            print("!!! getdata complete")
        } catch {
            print("!!! error \(error)")
            print(error)
        }
    }
    
    private func makeCurrencyItemViewModel(_ tokenItem: TokenItem) -> CurrencyItemViewModel {
        .init(tokenItem: tokenItem,
              isReadOnly: isDemoMode,
              isSelected: bindSelection(tokenItem))
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
        let alreadyAdded = self.isAdded(tokenItem)
        
        if selected {
            if alreadyAdded {
                self.pendingRemove.remove(tokenItem)
            } else {
                self.pendingAdd.append(tokenItem)
            }
        } else {
            if alreadyAdded {
                self.pendingRemove.append(tokenItem)
            } else {
                self.pendingAdd.remove(tokenItem)
            }
        }
    }
    
    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        if !canManage(tokenItem) {
            return .constant(isDemoMode ? false : true) //already added, cannot be removed
        }
        
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
