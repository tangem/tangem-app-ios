//
//  DetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk

class DetailsViewModel: ObservableObject {
    @Binding var sdkService: TangemSdkService
    
    @Published var isRefreshing = false
    @Published var showQr = false
    @Published var showCreatePayid = false
    @Published var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    init(cardViewModel: CardViewModel, sdkService: Binding<TangemSdkService>) {
        self._sdkService = sdkService
        self.cardViewModel = cardViewModel
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink(receiveValue: { [unowned self] _ in
                self.cardViewModel.updateWallet()
            })
            .store(in: &bag)
        
        cardViewModel.$isWalletLoading
            .removeDuplicates()
            .filter { !$0 }
            .sink (receiveValue: {[unowned self] isWalletLoading in
                self.isRefreshing = isWalletLoading
            })
            .store(in: &bag)
        
        cardViewModel.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        .store(in: &bag)
    }
    
    
    func scan() {
        sdkService.scan { [weak self] scanResult in
            switch scanResult {
            case .success(let card):
                self?.cardViewModel = CardViewModel(card: card)
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
}
