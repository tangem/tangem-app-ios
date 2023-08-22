//
//  OrganizeTokensHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeTokensHeaderViewModel: ObservableObject {
    @Published var isSortByBalanceEnabled = false

    var sortByBalanceButtonTitle: String {
        return Localization.organizeTokensSortByBalance
    }

    @Published var isGroupingEnabled = false

    var groupingButtonTitle: String {
        return isGroupingEnabled
            ? Localization.organizeTokensUngroup
            : Localization.organizeTokensGroup
    }

    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    private let organizeTokensOptionsEditing: OrganizeTokensOptionsEditing

    private var bag: Set<AnyCancellable> = []

    init(
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding,
        organizeTokensOptionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
        self.organizeTokensOptionsEditing = organizeTokensOptionsEditing
    }

    func onViewAppear() {
        bind()
    }

    func toggleSortState() {
        organizeTokensOptionsEditing.sort(by: isSortByBalanceEnabled ? .manual : .byBalance)
    }

    func toggleGroupState() {
        organizeTokensOptionsEditing.group(by: isGroupingEnabled ? .none : .byBlockchainNetwork)
    }

    private func bind() {
        organizeTokensOptionsProviding
            .groupingOption
            .map(\.isGrouped)
            .assign(to: \.isGroupingEnabled, on: self, ownership: .weak)
            .store(in: &bag)

        organizeTokensOptionsProviding
            .sortingOption
            .map(\.isSorted)
            .assign(to: \.isSortByBalanceEnabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
