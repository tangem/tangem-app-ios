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
    
    @Published var enteredSearchText = ""
    @Published var searchText = ""
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
        
        if let walletManager = cardModel.walletModels?.first(where: { $0.wallet.blockchain == tokenItem.blockchain })?.walletManager {
            if let token = tokenItem.token {
                return walletManager.cardTokens.contains(token)
            } else {
                return true
            }
        }
        
        return false
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
            self.enteredSearchText = ""
            self.searchText = ""
        }
    }
    
    func onCollapse(_ section: SectionModel) {
        if let index = data.firstIndex(where: { $0.id == section.id }) {
            data[index].toggleExpanded()
        }
    }
    
    private func getData()  {
        self.data = Sections.allCases.compactMap { $0.sectionModel(for: cardModel.cardInfo, isAdded: isAdded, onTap: onItemTap) }
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
        
        func sectionModel(for cardInfo: CardInfo, isAdded: (TokenItem) -> Bool, onTap: @escaping (String, TokenItem) -> Void) -> SectionModel? {
            let items = tokenItems(curves: cardInfo.card.walletCurves,
                                   isTestnet: cardInfo.isTestnet)
                .map { TokenModel(tokenItem: $0,
                                  sectionId: rawValue,
                                  isAdded: isAdded($0),
                                  onTap: onTap) }
            
            guard !items.isEmpty else { return nil }
            
            return SectionModel(id: rawValue,
                                name: sectionName(isTestnet: cardInfo.isTestnet),
                                items: items,
                                collapsible: collapsible,
                                expanded: true)
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
    var canAdd: Bool = true
    
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
