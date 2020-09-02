//
//  ExtractViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class ExtractViewModel: ObservableObject {
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    @Published var isSendEnabled: Bool = false
    
    private var bag = Set<AnyCancellable>()
    
    init(cardViewModel: Binding<CardViewModel>, sdkSerice: Binding<TangemSdkService>) {
        self._sdkService = sdkSerice
        self._cardViewModel = cardViewModel
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        
        cardViewModel.objectWillChange
              .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
        }
        .store(in: &bag)
    }
}
