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

class SettingsViewModel: ObservableObject {
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    init(cardViewModel: Binding<CardViewModel>, sdkSerice: Binding<TangemSdkService>) {
        self._sdkService = sdkSerice
        self._cardViewModel = cardViewModel
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        
        cardViewModel.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
        .store(in: &bag)
    }
    
    func purgeWallet() {
        sdkService.purgeWallet(cardId: cardViewModel.card.cardId) { [weak self] result in
            switch result {
            case .success(let cardViewModel):
                self?.cardViewModel = cardViewModel
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
}
