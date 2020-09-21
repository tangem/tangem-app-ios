//
//  SettingsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

class SettingsViewModel: ObservableObject {
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    @Published var canPurgeWallet: Bool = false

    private var bag = Set<AnyCancellable>()
    
    init(cardViewModel: Binding<CardViewModel>, sdkSerice: Binding<TangemSdkService>) {
        self._sdkService = sdkSerice
        self._cardViewModel = cardViewModel
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        canPurgeWallet = getPurgeWalletStatus()
        
        cardViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
        }
        .store(in: &bag)
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void ) {
        sdkService.purgeWallet(cardId: cardViewModel.card.cardId) { [weak self] result in
            switch result {
            case .success(let cardViewModel):
                guard let self = self else { return }
                
                self.cardViewModel = cardViewModel
                self.canPurgeWallet = self.getPurgeWalletStatus()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
                //[REDACTED_TODO_COMMENT]
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
        //[REDACTED_TODO_COMMENT]
        //        if card.cardData?.productMask?.contains(.idCard) ?? true {
        //             return false
        //        }
        //
        //        if card.cardData?.productMask?.contains(.idIssuer) ?? true {
        //             return false
        //        }
        
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
