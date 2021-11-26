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

class AddNewTokensViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    @Published var enteredSearchText = ""
    @Published var isLoading: Bool = false
    
    lazy var supportedItems = SupportedTokenItems()
    
    lazy var availableBlockchains: [TokenItem] = {
        supportedItems.blockchains(for: cardModel.cardInfo.card.walletCurves, isTestnet: cardModel.cardInfo.isTestnet)
            .sorted(by: { $0.displayName < $1.displayName })
            .map { TokenItem.blockchain($0) }
    }()
    
    lazy var availableEthereumTokens: [TokenItem] = {
        supportedItems.availableEthTokens(isTestnet: isTestnet).map { TokenItem.token($0) }
    }()
    
    lazy var availableBnbTokens: [TokenItem] = {
        supportedItems.availableBnbTokens(isTestnet: isTestnet).map { TokenItem.token($0) }
    }()
    
    lazy var availableBscTokens: [TokenItem] = {
        supportedItems.availableBscTokens(isTestnet: isTestnet).map { TokenItem.token($0) }
    }()
    
    @Published var searchText: String = ""
    @Published var error: AlertBinder?
    @Published var isEthTokensVisible: Bool = true
    @Published var isBnbTokensVisible: Bool = true
    @Published var isBscTokensVisible: Bool = true
    
    private var pendingTokenItems: [TokenItem] = []
    
    let cardModel: CardViewModel
    
    var isTestnet: Bool {
        cardModel.isTestnet
    }
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func getBlockchains(filter: String) -> [TokenItem] {
        getVisibleItems(availableBlockchains, filter)
    }
    
    func getVisibleEthTokens(filter: String) -> [TokenItem] {
        getVisibleItems(isEthTokensVisible ? availableEthereumTokens : [], filter)
    }
    
    func getVisibleBnbTokens(filter: String) -> [TokenItem] {
        getVisibleItems(isBnbTokensVisible ? availableBnbTokens : [], filter)
    }
    
    func getVisibleBscTokens(filter: String) -> [TokenItem] {
        getVisibleItems(isBscTokensVisible ? availableBscTokens : [], filter)
    }
    
    private func getVisibleItems(_ items: [TokenItem], _ filter: String) -> [TokenItem] {
        if filter.isEmpty {
            return items
        }
        
        let filter = filter.lowercased()
        
        return items.filter {
            $0.name.lowercased().contains(filter) || $0.symbol.lowercased().contains(filter)
        }
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
    
    func add(_ tokenItem: TokenItem) {
        pendingTokenItems.append(tokenItem)
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
    
    func clear() {
        searchText = ""
        pendingTokenItems = []
    }
}
