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
import TangemUIUtils

final class AddressBookContactManagementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contactName: String = ""
    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>
    @Published var selectedWallet: WalletRowType?

    @Published var isProcessing: Bool = false
    @Published var errorAlert: AlertBinder?

    @Published private var drafts: [DraftRow] = []

    var title: String { mode.title }

    var addressesSection: [AddressRowType] {
        var types: [AddressRowType] = drafts.map { draft in
            .address(
                AddressBookContactAddressRowViewModel(id: draft.id, address: draft.address) { [weak self] in
                    self?.deleteRow(id: draft.id)
                }
            )
        }

        types.append(.addNewAddress(AddressBookContactAddNewAddressRowViewModel(action: { [weak self] in
            self?.addNewAddress()
        })))

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

    // MARK: - Dependencies

    private weak var coordinator: AddressBookContactManagementRoutable?
    private let mode: Mode

    private var nameMode: AccountIconView.NameMode {
        if let firstLetter = contactName.trimmed().first {
            return .letter(String(firstLetter))
        }

        return .letter("")
    }

    init(
        mode: Mode,
        coordinator: AddressBookContactManagementRoutable
    ) {
        self.mode = mode
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
        Task { await save() }
    }
}

// MARK: - Private

private extension AddressBookContactManagementViewModel {
    func setupView(mode: Mode) {
        switch mode {
        case .add:
            drafts = []
        case .edit(let contact):
            contactName = contact.name
            drafts = contact.addresses.map { DraftRow(id: $0.id.uuidString, address: $0.address) }
            selectedWallet = .init(wallet: contact.walletName, isEditable: true)
        }
    }

    /// Mock: appends a synthetic EVM address. The full "enter address → detect networks → memo" flow
    /// is a follow-up; this exercises the create/add CRUD path end to end.
    func addNewAddress() {
        let address = "0x" + String((0 ..< 40).map { _ in "0123456789abcdef".randomElement()! })
        drafts.append(DraftRow(id: UUID().uuidString, address: address))
    }

    func deleteRow(id: String) {
        drafts.removeAll { $0.id == id }
    }

    @MainActor
    func save() async {
        guard !isProcessing else { return }

        let name = contactName.trimmed()
        guard !name.isEmpty, !drafts.isEmpty else {
            presentGenericError()
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        // [REDACTED_TODO_COMMENT]
        coordinator?.dismissContactManagement()
    }

    func presentGenericError() {
        errorAlert = AlertBinder(title: Localization.commonError, message: Localization.commonUnknownError)
    }
}

// MARK: - Types

extension AddressBookContactManagementViewModel {
    enum Mode {
        case add
        case edit(contact: AddressBookContact)

        var title: String {
            switch self {
            case .add: return Localization.addressBookAddContact
            case .edit: return "Contact"
            }
        }
    }

    struct DraftRow: Identifiable {
        let id: String
        var address: String
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

    struct WalletRowType: Identifiable {
        var id: String { wallet + isEditable.description }
        let wallet: String
        let isEditable: Bool
    }
}
