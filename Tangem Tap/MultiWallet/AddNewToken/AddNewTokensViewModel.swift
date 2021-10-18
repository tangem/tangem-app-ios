//
//  AddNewTokenViewModel.swift
//  Tangem Tap
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
    weak var tokenItemsRepository: TokenItemsRepository!
    
    @Published var enteredSearchText = ""
    
    var availableBlockchains: [Blockchain]  { get { tokenItemsRepository.supportedItems.blockchains(for: cardModel.cardInfo).sorted(by: { $0.displayName < $1.displayName }) } }
    
    var visibleEthTokens: [Token] {
        isEthTokensVisible ?
            availableEthereumTokens :
            []
    }
    
    var availableEthereumTokens: [Token]  {
        isTestnet ?
            tokenItemsRepository.supportedItems.ethereumTokensTestnet :
            tokenItemsRepository.supportedItems.ethereumTokens
    }
    
    var visibleBnbTokens: [Token] {
        isBnbTokensVisible ?
            availableBnbTokens :
            []
    }
    
    var availableBnbTokens: [Token] {
        isTestnet ?
            tokenItemsRepository.supportedItems.binanceTokensTestnet :
            tokenItemsRepository.supportedItems.binanceTokens
    }
    
    var visibleBscTokens: [Token] {
        isBscTokensVisible ?
            availableBscTokens :
            []
    }
    var availableBscTokens: [Token] {
        isTestnet ?
            tokenItemsRepository.supportedItems.binanceSmartChainTokensTestnet :
            tokenItemsRepository.supportedItems.binanceSmartChainTokens
    }
    
    @Published var searchText: String = ""
    @Published private(set) var pendingTokensUpdate: Set<Token> = []
    @Published var error: AlertBinder?
    @Published var isEthTokensVisible: Bool = true
    @Published var isBnbTokensVisible: Bool = true
    @Published var isBscTokensVisible: Bool = true
    
    let cardModel: CardViewModel
    
    var isTestnet: Bool {
        cardModel.isTestnet
    }
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func addBlockchain(_ blockchain: Blockchain) {
        cardModel.addBlockchain(blockchain)
    }
    
    func isAdded(_ token: Token) -> Bool {
        tokenItemsRepository.items.contains(where: { $0.token == token })
    }
    
    func isAdded(_ blockchain: Blockchain) -> Bool {
        cardModel.wallets!.contains(where: { $0.blockchain == blockchain })
    }
    
    func addTokenToList(token: Token, blockchain: Blockchain) {
        pendingTokensUpdate.insert(token)
        cardModel.addToken(token, blockchain: blockchain) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.pendingTokensUpdate.remove(token)
            case .failure(let error):
                self.error = error.alertBinder
                self.pendingTokensUpdate.remove(token)
            }
        }
    }
    
    func clear() {
        searchText = ""
        pendingTokensUpdate = []
    }
    
}
