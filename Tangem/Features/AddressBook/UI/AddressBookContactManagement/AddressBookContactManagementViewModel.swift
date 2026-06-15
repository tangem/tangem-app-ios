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
import TangemUI
import TangemMacro

final class AddressBookContactManagementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contactName: String = ""
    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>
    @Published private(set) var selectedWallet: WalletRowType?
    @Published private(set) var mainButtonState: MainButtonState = .disabled
    @Published private(set) var canDeleteContact: Bool = false

    @Published private(set) var isProcessing: Bool = false

    @Published var errorAlert: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    @Published private var drafts: [DraftRow] = []
    @Published private var canAddNewAddress: Bool = true

    let title: String

    var maxNameLength: Int { AccountModelUtils.maxAccountNameLength }

    let colors: [GridItemColor] = AccountModel.CompositeIcon.Color
        .allCases
        .map { iconColor in
            GridItemColor(id: iconColor, color: AccountModelUtils.UI.iconColor(from: iconColor))
        }

    var addressesSection: [AddressRowType] {
        var types: [AddressRowType] = drafts.map { draft in
            .address(
                AddressBookContactAddressRowViewModel(id: draft.id, address: draft.address) { [weak self] in
                    self?.deleteRow(id: draft.id)
                }
            )
        }

        if canAddNewAddress {
            types.append(.addNewAddress(AddressBookContactAddNewAddressRowViewModel(action: { [weak self] in
                self?.addNewAddress()
            })))
        }

        return types
    }

    var iconViewData: AccountIconView.ViewData {
        .composite(
            backgroundColor: AccountModelUtils.UI.iconColor(from: selectedColor.id),
            nameMode: nameMode
        )
    }

    // MARK: - Dependencies

    private let interactor: AddressBookContactManagementInteractor
    private weak var coordinator: AddressBookContactManagementRoutable?
    private var bag = Set<AnyCancellable>()

    private var nameMode: AccountIconView.NameMode {
        if let firstLetter = contactName.trimmed().first {
            return .letter(String(firstLetter))
        }

        return .letter("")
    }

    init(
        interactor: AddressBookContactManagementInteractor,
        coordinator: AddressBookContactManagementRoutable
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        title = interactor.title

        let newIcon = AccountModelUtils.UI.newAccountIcon()
        selectedColor = GridItemColor(
            id: newIcon.color,
            color: AccountModelUtils.UI.iconColor(from: newIcon.color)
        )

        bind()
    }

    func userDidRequestDismiss() {
        coordinator?.dismissContactManagement()
    }

    func userDidRequestWalletChange() {
        // [REDACTED_TODO_COMMENT]
    }

    func userDidRequestDone() {
        Task { await save() }
    }

    func userDidRequestDelete() {
        confirmationDialog = ConfirmationDialogViewModel(
            title: nil,
            subtitle: Localization.addressBookDeleteContactDescription,
            buttons: [
                .init(title: "Delete", role: .destructive) { [weak self] in
                    guard let self else { return }
                    Task { await self.delete() }
                },
            ]
        )
    }
}

// MARK: - Private

private extension AddressBookContactManagementViewModel {
    func bind() {
        interactor.contactNamePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$contactName)

        $contactName
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { $0.interactor.update(name: $1) }
            .store(in: &bag)

        interactor.contactColorPublisher
            .removeDuplicates()
            .map { color in GridItemColor(id: color, color: AccountModelUtils.UI.iconColor(from: color)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedColor)

        $selectedColor
            .map(\.id)
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { $0.interactor.update(color: $1) }
            .store(in: &bag)

        interactor.addressesPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$drafts)

        interactor.walletPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedWallet)

        interactor.possibleToAddNewAddress
            .receive(on: DispatchQueue.main)
            .assign(to: &$canAddNewAddress)

        interactor.possibleToDeleteContact
            .receive(on: DispatchQueue.main)
            .assign(to: &$canDeleteContact)

        interactor.mainButtonStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$mainButtonState)
    }

    /// Mock: appends a synthetic EVM address. The full "enter address → detect networks → memo" flow
    /// is a follow-up; this exercises the create/add CRUD path end to end.
    func addNewAddress() {
        let address = "0x" + String((0 ..< 40).map { _ in "0123456789abcdef".randomElement()! })
        try? interactor.add(address: DraftRow(id: UUID().uuidString, address: address))
    }

    func deleteRow(id: String) {
        interactor.deleteAddress(id: id)
    }

    @MainActor
    func save() async {
        guard !isProcessing else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            try await interactor.save()
            coordinator?.dismissContactManagement()
        } catch {
            guard !error.isCancellationError else { return }

            presentGenericError()
        }
    }

    @MainActor
    func delete() async {
        guard !isProcessing else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            try await interactor.delete()
            coordinator?.dismissContactManagement()
        } catch {
            guard !error.isCancellationError else { return }

            presentGenericError()
        }
    }

    func presentGenericError() {
        errorAlert = AlertBinder(title: Localization.commonError, message: Localization.commonUnknownError)
    }
}

// MARK: - Types

extension AddressBookContactManagementViewModel {
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

    @CaseFlagable
    enum MainButtonState {
        case disabled
        case enabled(icon: MainButton.Icon?)
    }
}
