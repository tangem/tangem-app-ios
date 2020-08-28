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
                self.cardViewModel.updateWallet()
            })
            .store(in: &bag)
        
        cardViewModel.$isWalletLoading
            .removeDuplicates()
            .filter { !$0 }
            .sink (receiveValue: {[unowned self] isWalletLoading in
                DispatchQueue.main.async {
                      self.isRefreshing = isWalletLoading
                }
            })
            .store(in: &bag)
        
        cardViewModel.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
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
}
