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
    
    
    private var bag = Set<AnyCancellable>()
    
    init(sdkService: Binding<TangemSdkService>) {
        self._sdkService = sdkService
    }
    
    func bind(cardViewModel: CardViewModel) {
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink(receiveValue: { _ in
                cardViewModel.updateWallet()
            })
            .store(in: &bag)
        
        cardViewModel.$isWalletLoading
            .removeDuplicates()
            .filter { !$0 }
            .sink (receiveValue: {[unowned self] isWalletLoading in
                self.isRefreshing = isWalletLoading
            })
            .store(in: &bag)
    }
}
