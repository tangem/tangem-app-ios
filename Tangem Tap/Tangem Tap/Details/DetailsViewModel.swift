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
    @Published var showSettings = false
    @Published var showSend = false
    @Published var showSendChoise = false
    @Published var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    var amountToSend: Amount? = nil
    
    private var bag = Set<AnyCancellable>()
    
    init(cid: String, sdkService: Binding<TangemSdkService>) {
        self._sdkService = sdkService
        self.cardViewModel = sdkService.wrappedValue.cards[cid]!
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink(receiveValue: { [unowned self] _ in
                self.cardViewModel.update()
            })
            .store(in: &bag)
        
        cardViewModel.$isWalletLoading
            .removeDuplicates()
            .filter { !$0 }
            .receive(on: RunLoop.main)
            .sink (receiveValue: {[unowned self] isWalletLoading in
                self.isRefreshing = isWalletLoading
            })
            .store(in: &bag)
        
        cardViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
        }
        .store(in: &bag)
    }
    
    
    func scan() {
        sdkService.scan { [weak self] scanResult in
            switch scanResult {
            case .success(let cardViewModel):
                self?.cardViewModel = cardViewModel
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
    
    func createWallet() {
        sdkService.createWallet(cardId: cardViewModel.card.cardId) { [weak self] result in
            switch result {
            case .success(let cardViewModel):
                self?.cardViewModel = cardViewModel
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
    
    func sendTapped() {
        if cardViewModel.wallet!.amounts.count > 1 {
            showSendChoise = true
        } else {
            amountToSend = Amount(with: cardViewModel.wallet!.amounts.first!.value, value: 0)
            showSend = true
        }
    }
}
