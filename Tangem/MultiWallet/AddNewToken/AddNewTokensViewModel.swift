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
import SwiftUI

class AddNewTokensViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    @Published var searchText = ""
    @Published var enteredSearchText = ""
    @Published var isLoading: Bool = false
    @Published var error: AlertBinder?
    @Published var pendingTokenItems: [TokenItem] = []
    @Published var data: [SectionModel] = []
    
    private let cardModel: CardViewModel
    private var isTestnet: Bool {  cardModel.isTestnet }

    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func isAdded(_ tokenItem: TokenItem) -> Bool {
        if pendingTokenItems.contains(tokenItem) {
            return true
        }
        
        guard let wallets = cardModel.wallets else { return false }
        
        if let token = tokenItem.token {
            return wallets.contains(where: { $0.amounts.contains(where: { $0.key.token == token })})
        } else {
            return wallets.contains(where: { $0.blockchain == tokenItem.blockchain })
        }
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
            if let itemIndex = data[index].items.firstIndex(where: { $0.id == tokenItem.id }) {
                data[index].items[itemIndex].isAdded = isAdded(tokenItem)
            }
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
                self.error = error.alertBinder
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
            self.searchText = ""
        }
    }

    func onCollapse(_ section: SectionModel) {
        if let index = data.firstIndex(where: { $0.id == section.id }) {
            data[index].toggleExpanded()
        }
    }
    
    private func getData()  {
        var listData: [SectionModel] = []
        
        let supportedItems = SupportedTokenItems()
        
        let blockchainsItems: [TokenModel] =
        supportedItems.blockchains(for: cardModel.cardInfo.card.walletCurves, isTestnet: cardModel.cardInfo.isTestnet)
            .sorted(by: { $0.displayName < $1.displayName })
            .map { TokenItem.blockchain($0) }
            .map { TokenModel(tokenItem: $0, sectionId: Sections.blockchains.rawValue, isAdded: isAdded($0), onTap: onItemTap) }
        
        listData.append(SectionModel(id: Sections.blockchains.rawValue,
                                     name: "add_token_section_title_blockchains".localized,
                                     items: blockchainsItems,
                                     collapsible: false,
                                     expanded: true))
        
        let ethItems: [TokenModel] = supportedItems.availableEthTokens(isTestnet: isTestnet)
            .map { TokenItem.token($0) }
            .map { TokenModel(tokenItem: $0, sectionId: Sections.eth.rawValue, isAdded: isAdded($0), onTap: onItemTap) }
        
        listData.append(SectionModel(id: Sections.eth.rawValue,
                                     name: "add_token_section_title_popular_tokens".localized,
                                     items: ethItems,
                                     collapsible: true,
                                     expanded: true))
        
        let bscItems: [TokenModel] = supportedItems.availableBscTokens(isTestnet: isTestnet)
            .map { TokenItem.token($0) }
            .map { TokenModel(tokenItem: $0, sectionId: Sections.bsc.rawValue, isAdded: isAdded($0), onTap: onItemTap) }
        
        listData.append(SectionModel(id: Sections.bsc.rawValue,
                                     name: "add_token_section_title_binance_smart_chain_tokens".localized,
                                     items: bscItems,
                                     collapsible: true,
                                     expanded: true))
        
        let bnbItems: [TokenModel] = supportedItems.availableBnbTokens(isTestnet: isTestnet)
            .map { TokenItem.token($0) }
            .map { TokenModel(tokenItem: $0, sectionId: Sections.bnb.rawValue, isAdded: isAdded($0), onTap: onItemTap) }
        
        listData.append(SectionModel(id: Sections.bnb.rawValue,
                                     name: "add_token_section_title_binance_tokens".localized,
                                     items: bnbItems,
                                     collapsible: true,
                                     expanded: true))
        
        self.data = listData
    }
}

extension AddNewTokensViewModel {
    enum Sections: String {
        case blockchains
        case eth
        case bsc
        case bnb
    }
}


struct SectionModel: Identifiable, Hashable {
    let id: String
    let name: String
    var items: [TokenModel]
    let collapsible: Bool
    var expanded: Bool
    
    func searchResults(_ searchText: String) -> [TokenModel] {
        if searchText.isEmpty {
            return items
        } else {
            let filter = searchText.lowercased()
            
            return items.filter {
                $0.tokenItem.name.lowercased().contains(filter)
                || $0.tokenItem.symbol.lowercased().contains(filter)
            }
        }
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
