//
//  ManageTokensNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ManageTokensNetworkSelectorItemViewModel: Identifiable, ObservableObject {
    let id: Int
    var iconName: String { selectedPublisher ? _iconNameSelected : _iconName }
    var isSelected: Binding<Bool>
    let isAvailable: Bool

    let networkName: String
    let isMain: Bool
    let tokenTypeName: String?

    @Published var selectedPublisher: Bool

    private let _iconName: String
    private let _iconNameSelected: String
    private var bag = Set<AnyCancellable>()

    init(
        id: Int,
        isMain: Bool,
        iconName: String,
        iconNameSelected: String,
        networkName: String,
        tokenTypeName: String?,
        isSelected: Binding<Bool>,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.isMain = isMain
        _iconName = iconName
        _iconNameSelected = iconNameSelected
        self.networkName = networkName
        self.tokenTypeName = tokenTypeName
        self.isSelected = isSelected
        self.isAvailable = isAvailable

        selectedPublisher = isSelected.wrappedValue

        $selectedPublisher
            .dropFirst()
            .sink { [weak self] value in
                self?.isSelected.wrappedValue = value
            }
            .store(in: &bag)
    }

    // MARK: - Implementation

    func updateSelection(with isSelected: Binding<Bool>) {
        self.isSelected = isSelected
        selectedPublisher = isSelected.wrappedValue
    }
}
