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

class AddNewTokensViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    @Published var availableTokens: [Token] = []
    
    @Published var searchText: String = ""
    
    @Published private(set) var tokensToSave: Set<Token> = []
    @Published private(set) var pendingTokensUpdate: Set<Token> = []
    @Published var error: AlertBinder?
    
    private var bag: Set<AnyCancellable> = []
    
    let walletModel: WalletModel
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
    
    func onAppear() {
        availableTokens = walletModel.tokensService?.availableTokens ?? []
    }
    
    func addTokenToList(token: Token) {
        pendingTokensUpdate.insert(token)
        tokensToSave.insert(token)
        walletModel.addToken(token)?
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    print("Failed to add token to model", error)
                    self.error = error.alertBinder
                    self.pendingTokensUpdate.remove(token)
                    self.tokensToSave.remove(token)
                }
            }, receiveValue: { _ in
                self.pendingTokensUpdate.remove(token)
            })
            .store(in: &bag)
    }
    
    func removeTokenFromList(token: Token) {
        tokensToSave.remove(token)
    }
    
    func clear() {
        searchText = ""
        tokensToSave = []
        pendingTokensUpdate = []
        bag = []
    }
    
}
