//
//  DetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

class DetailsViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator! {
        didSet {
            navigation.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    var assembly: Assembly!
    var cardsRepository: CardsRepository!
    var bag = Set<AnyCancellable>()
    
    @Published var cardViewModel: CardViewModel! {
        didSet {
            bind()
        }
    }
    
    @Published var canPurgeWallet: Bool = false
    
    var canManageSecurity: Bool {
        cardViewModel.card.isPin1Default != nil &&
            cardViewModel.card.isPin2Default != nil
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        canPurgeWallet = getPurgeWalletStatus()
        
        cardViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void ) {
        cardsRepository.purgeWallet(card: cardViewModel.card) { [weak self] result in
            switch result {
            case .success(let cardViewModel):
                guard let self = self else { return }
                
                self.cardViewModel = cardViewModel
                self.canPurgeWallet = self.getPurgeWalletStatus()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    private func getPurgeWalletStatus() -> Bool {
        if let status = cardViewModel.card.status, status == .empty {
            return false
        }
        
        if (cardViewModel.card.settingsMask?.contains(.prohibitPurgeWallet) ?? false) {
            return false
        }
        
        if let wallet = cardViewModel.wallet {
            if let loadingError = cardViewModel.loadingError {
                if case .noAccount(_) = (loadingError as? WalletError) {
                    return true
                } else {
                    return false
                }
            }
            
            if !wallet.isEmptyAmount || wallet.hasPendingTx {
                return false
            }
            
            return true
        } else {
            return false
        }
    }
}
