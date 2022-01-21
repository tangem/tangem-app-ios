//
//  AddNewTokenViewModel.swift
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

class AddNewTokensViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    var enteredSearchText = CurrentValueSubject<String, Never>("") //I can't use @Published here, because of swiftui redraw perfomance drop
    @Published var isLoading: Bool = false
    @Published var isSearching: Bool = false
    @Published var error: AlertBinder?
    @Published var pendingTokenItems: [TokenItem] = []
    @Published var data: [SectionModel] = []
    
    private let cardModel: CardViewModel
    private var isTestnet: Bool {  cardModel.isTestnet }
    private var bag = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable? = nil
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
        
        enteredSearchText
            .sink { [unowned self] string in
                self.startSearch(with: string)
            }
            .store(in: &bag)
    }
    
    func startSearch(with searchText: String) {
        isSearching = true
        searchCancellable =
        Just(searchText)
            .receive(on: DispatchQueue.global(), options: nil)
            .map {[unowned self] string in
                return self.data.map { $0.search(string) }
            }
            .receive(on: DispatchQueue.main, options: nil)
            .sink(receiveValue: {[unowned self] results in
                results.forEach { result in
                    if let index = data.firstIndex(where: { $0.id == result.0 }) {
                        self.data[index].applySearch(result.1)
                    }
                }
                
                self.isSearching = false
            })
    }
    
    func isAdded(_ tokenItem: TokenItem) -> Bool {
        if pendingTokenItems.contains(tokenItem) {
            return true
        }
        
        return !canAdd(tokenItem)
    }
    
    func canAdd(_ tokenItem: TokenItem) -> Bool {
        if let walletManager = cardModel.walletModels?.first(where: { $0.wallet.blockchain == tokenItem.blockchain })?.walletManager {
            if let token = tokenItem.token {
                return !walletManager.cardTokens.contains(token)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func onItemTap(_ sectionId: String, _ tokenItem: TokenItem) -> Void {
        if isAdded(tokenItem) {
            if pendingTokenItems.contains(tokenItem) {
                pendingTokenItems.remove(tokenItem)
            }
        } else {
            pendingTokenItems.append(tokenItem)
        }
        
        if let index = data.firstIndex(where: { $0.id == sectionId }) {
            data[index].onTap(tokenItem, isAdded: isAdded(tokenItem))
        }
        
    }
    
    func saveChanges() {
        isLoading = true
        
        cardModel.addTokenItems(pendingTokenItems) { result in
            self.isLoading = false
            switch result {
            case .success:
                self.navigation.mainToAddTokens = false
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {} else {
                    self.error = error.alertBinder
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
            self.pendingTokenItems = []
            self.data = []
            self.enteredSearchText.value = ""
        }
    }
    
    func onCollapse(_ section: SectionModel) {
        if let index = data.firstIndex(where: { $0.id == section.id }) {
            data[index].toggleExpanded()
        }
    }
    
    private func getData()  {
        self.data = Sections.allCases.compactMap { $0.sectionModel(for: cardModel.cardInfo, isAdded: isAdded, canAdd: canAdd, onTap: onItemTap) }
    }
}

extension AddNewTokensViewModel {
    enum Sections: String, CaseIterable {
        case blockchains
        case eth
        case bsc
        case bnb
        case polygon
        case avalanche
        case solana
        
        private var collapsible: Bool {
            switch self {
            case .blockchains:
                return false
            default:
                return true
            }
        }
        
        func sectionModel(for cardInfo: CardInfo,
                          isAdded: (TokenItem) -> Bool,
                          canAdd: (TokenItem) -> Bool,
                          onTap: @escaping (String, TokenItem) -> Void) -> SectionModel? {
            let items = tokenItems(curves: cardInfo.card.walletCurves,
                                   isTestnet: cardInfo.isTestnet)
                .map { TokenModel(tokenItem: $0,
                                  sectionId: rawValue,
                                  isAdded: isAdded($0),
                                  canAdd: canAdd($0),
                                  onTap: onTap) }
            
            guard !items.isEmpty else { return nil }
            
            return SectionModel(id: rawValue,
                                name: sectionName(isTestnet: cardInfo.isTestnet),
                                items: items,
                                collapsible: collapsible,
                                expanded: !collapsible)
        }
        
        private func tokenBlockchain(isTestnet: Bool) -> Blockchain {
            switch self {
            case .blockchains:
                fatalError("Impossible is possible")
            case .eth:
                return .ethereum(testnet: isTestnet)
            case .bsc:
                return .bsc(testnet: isTestnet)
            case .bnb:
                return .binance(testnet: isTestnet)
            case .polygon:
                return .polygon(testnet: isTestnet)
            case .avalanche:
                return .avalanche(testnet: isTestnet)
            case .solana:
                return .solana(testnet: isTestnet)
            }
        }
        
        private func sectionName(isTestnet: Bool) -> String {
            switch self {
            case .blockchains:
                return "add_token_section_title_blockchains".localized
            default:
                return "add_token_section_title_tokens_format".localized(tokenBlockchain(isTestnet: isTestnet).displayName)
            }
        }
        
        private func tokenItems(curves: [EllipticCurve], isTestnet: Bool) -> [TokenItem] {
            let supportedItems = SupportedTokenItems()
            
            switch self {
            case .blockchains:
                return supportedItems.blockchains(for: curves, isTestnet: isTestnet)
                    .sorted(by: { $0.displayName < $1.displayName })
                    .map { TokenItem.blockchain($0) }
            default:
                let tokenBlockchain = self.tokenBlockchain(isTestnet: isTestnet)
                guard curves.contains(tokenBlockchain.curve) else {
                    return []
                }
                
                return supportedItems.tokens(for: tokenBlockchain)
                    .map { TokenItem.token($0) }
            }
        }
    }
}

struct SectionModel: Identifiable, Hashable {
    let id: String
    let name: String
    let collapsible: Bool
    var expanded: Bool
    
    var items: [TokenModel] { expanded ? (filteredItems ?? rawItems) : [] }
    
    private var filteredItems: [TokenModel]? = nil
    private var rawItems: [TokenModel]
    
    init(id: String, name: String, items: [TokenModel], collapsible: Bool, expanded: Bool) {
        self.id = id
        self.name = name
        self.collapsible = collapsible
        self.expanded = expanded
        self.rawItems = items
    }
    
    mutating func onTap(_ item: TokenItem, isAdded: Bool) {
        if let itemIndex = rawItems.firstIndex(where: { $0.id == item.id }) {
            rawItems[itemIndex].isAdded = isAdded
        }
        
        if let itemIndex = filteredItems?.firstIndex(where: { $0.id == item.id }) {
            filteredItems?[itemIndex].isAdded = isAdded
        }
    }
    
    mutating func applySearch(_ results: [TokenModel]?) {
        if filteredItems == nil && results == nil {
            return
        }
        
        filteredItems = results
    }
    
    func search(_ searchText: String) -> (String, [TokenModel]?)  {
        if searchText.isEmpty {
            return (id, nil)
        }
        
        let filter = searchText.lowercased()
        
        let filtered  = self.items.filter {
            $0.tokenItem.name.lowercased().contains(filter)
            || $0.tokenItem.symbol.lowercased().contains(filter)
        }
        .sorted(by: { lhs, rhs in
            if lhs.tokenItem.name.lowercased() == filter
                || lhs.tokenItem.symbol.lowercased() == filter {
                return true
            }

            return false
        })
        
        return (id, filtered)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(expanded)
    }
    
    mutating func toggleExpanded() {
        expanded.toggle()
    }
    
    static func == (lhs: SectionModel, rhs: SectionModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct TokenModel: Identifiable, Hashable {
    var id: Int { tokenItem.id }
    let tokenItem: TokenItem
    var sectionId: String
    var isAdded: Bool
    var canAdd: Bool = true
    
    var subtitle: String {
        var string = tokenItem.symbol
        
        if let contractAddress = tokenItem.contractAddress {
            let addressFormater = AddressFormatter(address: contractAddress)
            string += " (\(addressFormater.truncated()))"
        }
        
       return string
    }
    
    
    var onTap: (String, TokenItem) -> Void

    func tap() {
        onTap(sectionId, tokenItem)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isAdded)
    }
    
    static func == (lhs: TokenModel, rhs: TokenModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
