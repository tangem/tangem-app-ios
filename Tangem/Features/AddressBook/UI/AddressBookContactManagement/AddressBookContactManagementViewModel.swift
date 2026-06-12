//
//  AddressBookContactManagementViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemAccounts
import TangemFoundation

final class AddressBookContactManagementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contactName: String = ""
    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>

    var addressesSection: [AddressRowType] {
        var types: [AddressRowType] = addressesRowViewModels.map { .address($0) }

        if let addNewAddressRowViewModel {
            types.append(.addNewAddress(addNewAddressRowViewModel))
        }

        return types
    }

    var maxNameLength: Int { AccountModelUtils.maxAccountNameLength }

    let colors: [GridItemColor] = AccountModel.CompositeIcon.Color
        .allCases
        .map { iconColor in
            GridItemColor(id: iconColor, color: AccountModelUtils.UI.iconColor(from: iconColor))
        }

    var iconViewData: AccountIconView.ViewData {
        .composite(
            backgroundColor: AccountModelUtils.UI.iconColor(from: selectedColor.id),
            nameMode: nameMode
        )
    }

    @Published private var addressesRowViewModels: [AddressBookContactAddressRowViewModel] = []
    @Published private var addNewAddressRowViewModel: AddressBookContactAddNewAddressRowViewModel?


    // MARK: - Dependencies

    private weak var coordinator: AddressBookContactManagementRoutable?

    private var nameMode: AccountIconView.NameMode {
        if let firstLetter = contactName.trimmed().first {
            return .letter(String(firstLetter))
        }

        return .letter("")
    }

    init(coordinator: AddressBookContactManagementRoutable) {
        self.coordinator = coordinator

        let newIcon = AccountModelUtils.UI.newAccountIcon()
        selectedColor = GridItemColor(
            id: newIcon.color,
            color: AccountModelUtils.UI.iconColor(from: newIcon.color)
        )
    }

    func dismiss() {
        coordinator?.dismissContactManagement()
    }
}

// MARK: - Private

private extension AddressBookContactManagementViewModel {
    func setupView() {
    }
}

// MARK: - Types

extension AddressBookContactManagementViewModel {
    enum AddressRowType: Identifiable {
        var id: String {
            switch self {
            case .address(let viewModel): viewModel.id
            case .addNewAddress(let viewModel): "AddressBookContactAddNewAddressRowViewModel"
            }
        }

        case address(AddressBookContactAddressRowViewModel)
        case addNewAddress(AddressBookContactAddNewAddressRowViewModel)
    }
}
