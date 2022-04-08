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
    let isReadonly: Bool
    let isDisabled: Bool
    let isSelected: Binding<Bool>
    let position: ItemPosition
    let isCopied: Binding<Bool>
    
    @Published var selectedPublisher: Bool
    
    var isMain: Bool { tokenItem.isBlockchain }
    var imageName: String { tokenItem.blockchain.iconName  }
    var imageNameSelected: String { tokenItem.blockchain.iconNameFilled }
    var networkName: String { tokenItem.blockchain.displayName }
    var contractName: String? { tokenItem.contractName }
    var networkNameForegroundColor: Color { selectedPublisher ? .tangemGrayDark6 : Color(hex: "#848488")! }
    var contractNameForegroundColor: Color { tokenItem.isBlockchain ? .tangemGreen2 : Color(hex: "#AAAAAD")! }
    var hasContextMenu: Bool { tokenItem.isToken }
    
    private var bag = Set<AnyCancellable>()
    
    init(tokenItem: TokenItem, isReadonly: Bool, isDisabled: Bool, isSelected: Binding<Bool>, isCopied: Binding<Bool> = .constant(false), position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        self.isDisabled = isDisabled
        self.isSelected = isSelected
        self.isCopied = isCopied
        self.position = position
        self.selectedPublisher = isSelected.wrappedValue
        
        $selectedPublisher
            .dropFirst()
            .sink(receiveValue: {[unowned self] value in
                self.isSelected.wrappedValue = value
            })
            .store(in: &bag)
    }
    
    func onCopy() {
        if isReadonly { return }
        
        if let contractAddress = tokenItem.contractAddress {
            UIPasteboard.general.string = contractAddress
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            isCopied.wrappedValue = true
        }
    }
}

extension CurrencyItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CurrencyItemViewModel, rhs: CurrencyItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
