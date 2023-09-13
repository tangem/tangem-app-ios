//
//  ManageTokensNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class ManageTokensNetworkSelectorViewModel: ObservableObject {
    let isMain: Bool
    let iconName: String
    let networkName: String
    let tokenTypeName: String?

    var isSelected: Binding<Bool>

    @Published var selectedPublisher: Bool

    private var bag = Set<AnyCancellable>()

    init(isMain: Bool, iconName: String, networkName: String, tokenTypeName: String?, isSelected: Binding<Bool>) {
        self.isMain = isMain
        self.iconName = iconName
        self.networkName = networkName
        self.tokenTypeName = tokenTypeName
        self.isSelected = isSelected

        selectedPublisher = isSelected.wrappedValue

        $selectedPublisher
            .dropFirst()
            .sink { [weak self] value in
                self?.isSelected.wrappedValue = value
            }
            .store(in: &bag)
    }

    func updateSelection(with isSelected: Binding<Bool>) {
        self.isSelected = isSelected
        selectedPublisher = isSelected.wrappedValue
    }
}
