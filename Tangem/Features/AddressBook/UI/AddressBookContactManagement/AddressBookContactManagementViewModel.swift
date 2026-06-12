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
import TangemLocalization
import TangemFoundation

final class AddressBookContactManagementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contactName: String = ""
    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>

    var title: String { mode.title }

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
    private let addressBookManager: AddressBookManager
    private let mode: Mode

    private var nameMode: AccountIconView.NameMode {
        if let firstLetter = contactName.trimmed().first {
            return .letter(String(firstLetter))
        }

        return .letter("")
    }

    init(
        mode: Mode,
        addressBookManager: AddressBookManager,
        coordinator: AddressBookContactManagementRoutable
    ) {
        self.mode = mode
        self.addressBookManager = addressBookManager
        self.coordinator = coordinator

        let newIcon = AccountModelUtils.UI.newAccountIcon()
        selectedColor = GridItemColor(
            id: newIcon.color,
            color: AccountModelUtils.UI.iconColor(from: newIcon.color)
        )

        setupView(mode: mode)
    }

    func userDidRequestDismiss() {
        coordinator?.dismissContactManagement()
    }

    func userDidRequestDone() {
        // [REDACTED_TODO_COMMENT]
        coordinator?.dismissContactManagement()
    }
}

// MARK: - Private

private extension AddressBookContactManagementViewModel {
    func setupView(mode: Mode) {
        switch mode {
        case .add:
            break
        case .edit(let contact):
            contactName = contact.name.value
            addressesRowViewModels = contact.entries.map(AddressBookContactAddressRowViewModel.init)
        }

        addNewAddressRowViewModel = AddressBookContactAddNewAddressRowViewModel(
            action: { [weak self] in self?.addNewAddress() }
        )
    }

    func addNewAddress() {}
}

// MARK: - Types

extension AddressBookContactManagementViewModel {
    enum Mode {
        case add
        case edit(contact: Contact)

        var title: String {
            switch self {
            case .add: return Localization.addressBookAddContact
            case .edit: return "Contact"
            }
        }
    }

    enum AddressRowType: Identifiable {
        case address(AddressBookContactAddressRowViewModel)
        case addNewAddress(AddressBookContactAddNewAddressRowViewModel)

        var id: String {
            switch self {
            case .address(let viewModel): viewModel.id
            case .addNewAddress: "AddressBookContactAddNewAddressRowViewModel"
            }
        }
    }
}
