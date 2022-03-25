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
    let isDisabled: Bool
    let isSelected: Binding<Bool>
    let position: ItemPosition
    
    @Published var selectedPublisher: Bool
    
    var isMain: Bool { tokenItem.isBlockchain }
    var imageName: String { tokenItem.blockchain.iconName  }
    var imageNameSelected: String { tokenItem.blockchain.iconNameFilled }
    var networkName: String { tokenItem.blockchain.displayName }
    var contractName: String? { tokenItem.contractName }
    var networkNameForegroundColor: Color { selectedPublisher ? .tangemGrayDark6 : Color(hex: "#848488")! }
    var contractNameForegroundColor: Color { tokenItem.isBlockchain ? .tangemGreen2 : Color(hex: "#AAAAAD")! }
    
    private var bag = Set<AnyCancellable>()
    
    init(tokenItem: TokenItem, isReadOnly: Bool, isDisabled: Bool, isSelected: Binding<Bool>, position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isReadOnly = isReadOnly
        self.isDisabled = isDisabled
        self.isSelected = isSelected
        self.position = position
        self.selectedPublisher = isSelected.wrappedValue
        
        $selectedPublisher
            .sink(receiveValue: {[unowned self] value in
                self.isSelected.wrappedValue = value
            })
            .store(in: &bag)
    }
}
