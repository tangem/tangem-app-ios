//
//  CurrencyItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class CurrencyItemViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let tokenItem: TokenItem
    let isReadOnly: Bool
    let isSelected: Binding<Bool>
    
    @Published var selectedPublisher: Bool
    
    var imageName: String {  tokenItem.blockchain.iconName  }
    var imageNameSelected: String { tokenItem.blockchain.iconNameFilled }
    var networkName: String { tokenItem.networkName }
    
    var contractName: String? { tokenItem.blockchain.contractName }
    
    private var bag = Set<AnyCancellable>()
    
    init(tokenItem: TokenItem, isReadOnly: Bool, isSelected: Binding<Bool>) {
        self.tokenItem = tokenItem
        self.isReadOnly = isReadOnly
        self.isSelected = isSelected
        self.selectedPublisher = isSelected.wrappedValue
        
        $selectedPublisher
            .sink(receiveValue: {[unowned self] value in
                self.isSelected.wrappedValue = value
            })
            .store(in: &bag)
    }
}
