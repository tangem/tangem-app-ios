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
            contactName = contact.name.value
            drafts = contact.entries.map {
                DraftRow(id: $0.id.stringValue, entryId: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo)
            }
        }
    }

    /// Mock: appends a synthetic EVM address. The full "enter address → detect networks → memo" flow
    /// is a follow-up; this exercises the create/add CRUD path end to end.
    func addNewAddress() {
        let address = "0x" + String((0 ..< 40).map { _ in "0123456789abcdef".randomElement()! })
        drafts.append(DraftRow(id: UUID().uuidString, entryId: nil, address: address, networkId: AddressBookNetworkID("ethereum"), memo: nil))
    }

    func deleteRow(id: String) {
        drafts.removeAll { $0.id == id }
    }

    @MainActor
    func save() async {
        guard !isProcessing else { return }

        let name: ContactName
        do {
            name = try ContactName(validating: contactName)
        } catch {
            presentGenericError()
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            switch mode {
            case .add:
                guard !drafts.isEmpty else {
                    presentGenericError()
                    return
                }

                try await addressBookManager.createContact(name: name, entries: drafts.map(\.draft))
            case .edit(let contact):
                try await applyEdit(to: contact, name: name)
            }

            coordinator?.dismissContactManagement()
        } catch {
            guard !error.isCancellationError else { return }

            presentGenericError()
        }
    }

    /// Core edit scope: delete removed entries, re-sign on rename, add new entries. Editing an
    /// existing entry in place (updateEntry) is a follow-up.
    func applyEdit(to contact: Contact, name: ContactName) async throws {
        guard !drafts.isEmpty else {
            try await addressBookManager.deleteContact(id: contact.id)
            return
        }

        let currentEntryIds = Set(drafts.compactMap(\.entryId))
        let removedEntries = contact.entries.filter { !currentEntryIds.contains($0.id) }

        for entry in removedEntries {
            try await addressBookManager.deleteEntry(id: entry.id, fromContactWith: contact.id)
        }

        if name.value != contact.name.value {
            try await addressBookManager.renameContact(id: contact.id, to: name)
        }

        let addedDrafts = drafts.filter { $0.entryId == nil }.map(\.draft)

        if !addedDrafts.isEmpty {
            try await addressBookManager.addEntries(addedDrafts, toContactWith: contact.id)
        }
    }

    func presentGenericError() {
        errorAlert = AlertBinder(title: Localization.commonError, message: Localization.commonUnknownError)
    }
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

    struct DraftRow: Identifiable {
        let id: String
        let entryId: AddressEntryID?
        var address: String
        var networkId: AddressBookNetworkID
        var memo: String?

        var draft: AddressBookEntryDraft {
            AddressBookEntryDraft(address: address, networkId: networkId, memo: memo)
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
