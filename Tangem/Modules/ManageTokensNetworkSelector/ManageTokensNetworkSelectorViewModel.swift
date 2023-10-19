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

final class ManageTokensNetworkSelectorViewModel: Identifiable, ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published var selectorItems: [ManageTokensNetworkSelectorItemViewModel] = []

    // MARK: - Private Properties

    private unowned let coordinator: ManageTokensNetworkSelectorCoordinator

    // MARK: - Init

    // [REDACTED_TODO_COMMENT]
    init(tokenItems: [TokenItem], coordinator: ManageTokensNetworkSelectorCoordinator) {
        self.coordinator = coordinator
        selectorItems = tokenItems.map {
            .init(
                isMain: $0.isBlockchain,
                iconName: "",
                iconNameSelected: "",
                networkName: $0.networkName,
                tokenTypeName: $0.name,
                isSelected: .constant(false)
            )
        }
    }
}
