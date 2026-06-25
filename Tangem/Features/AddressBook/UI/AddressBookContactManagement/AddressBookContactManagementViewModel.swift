//
//  AddressBookContactManagementViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemAssets
import TangemAccounts
import TangemLocalization
import TangemFoundation
import TangemUIUtils
import TangemUI

final class AddressBookContactManagementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contactName: String = ""
    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>
    @Published private(set) var selectedWallet: WalletRowType?
    @Published private(set) var isMainButtonEnabled: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?
    @Published private(set) var canDeleteContact: Bool = false

    @Published private(set) var isProcessing: Bool = false

    @Published var errorAlert: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    @Published private var entries: AddressBookContactDraftEntries?
    @Published private var canAddNewAddress: Bool = true

    let title: String

    var maxNameLength: Int { AddressBookContactNameValidator.maxLength }

    let colors: [GridItemColor] = AccountModel.CompositeIcon.Color
        .allCases
        .map { iconColor in
            GridItemColor(id: iconColor, color: AccountModelUtils.UI.iconColor(from: iconColor))
        }

    @Published private(set) var addressesSection: [AddressRowType] = []

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
                .init(title: Localization.commonDelete, role: .destructive) { [weak self] in
                    guard let self else { return }
                    Task { await self.delete() }
                },
                .cancel,
            ]
        )
    }
}

// MARK: - Private

private extension AddressBookContactManagementViewModel {
    func bind() {
        interactor.contactNamePublisher
            .removeDuplicates()
            .receiveOnMain()
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
            .receiveOnMain()
            .assign(to: &$selectedColor)

        $selectedColor
            .map(\.id)
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { $0.interactor.update(color: $1) }
            .store(in: &bag)

        interactor.addressesPublisher
            .receiveOnMain()
            .assign(to: &$entries)

        interactor.walletPublisher
            .receiveOnMain()
            .assign(to: &$selectedWallet)

        interactor.possibleToAddNewAddress
            .receiveOnMain()
            .assign(to: &$canAddNewAddress)

        interactor.possibleToDeleteContact
            .receiveOnMain()
            .assign(to: &$canDeleteContact)

        interactor.isMainButtonEnabledPublisher
            .receiveOnMain()
            .assign(to: &$isMainButtonEnabled)

        interactor.mainButtonIconPublisher
            .receiveOnMain()
            .assign(to: &$mainButtonIcon)

        Publishers.CombineLatest($entries, $canAddNewAddress)
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                viewModel.makeAddressesSection(entries: args.0, canAddNewAddress: args.1)
            }
            .receiveOnMain()
            .assign(to: &$addressesSection)
    }

    func makeAddressesSection(entries: AddressBookContactDraftEntries?, canAddNewAddress: Bool) -> [AddressRowType] {
        // One row per address — an address may be saved in several networks; the row shows that count.
        let grouped = entries?.groupedByAddress ?? []
        var types: [AddressRowType] = grouped.map { group in
            .address(
                AddressBookContactAddressRowViewModel(
                    id: group.id,
                    address: group.address,
                    networksCount: group.networks.count
                ) { [weak self] in
                    self?.openAddressActions(for: group)
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

    func addNewAddress() {
        guard let wallet = selectedWallet else {
            return
        }

        coordinator?.openAddAddress(userWalletInfo: wallet.userWalletInfo, output: self, options: .add)
    }

    func editAddress(_ group: AddressBookContactAddressGroup) {
        guard let wallet = selectedWallet else {
            return
        }

        coordinator?.openAddAddress(
            userWalletInfo: wallet.userWalletInfo,
            output: self,
            options: .edit(address: group.address, memo: group.memo, replacing: group.networks.map(\.id))
        )
    }

    func deleteAddress(entryIds: [AddressBookAddressEntryID]) {
        entryIds.forEach { interactor.deleteAddress(id: $0) }
    }

    func openAddressActions(for group: AddressBookContactAddressGroup) {
        guard let coordinator else {
            return
        }

        let viewModel = AddressActionsViewModel(group: group, output: self, routable: coordinator)
        coordinator.presentAddressActions(viewModel)
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
            presentGenericError(message: error.localizedDescription)
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
            presentGenericError(message: error.localizedDescription)
        }
    }

    func presentGenericError(message: String) {
        errorAlert = AlertBinder(title: Localization.commonError, message: message)
    }
}

// MARK: - AddressBookAddAddressOutput

extension AddressBookContactManagementViewModel: AddressBookAddAddressOutput {
    func userDidAddAddress(entries: [AddressBookEntryDraft], replacing: [AddressBookAddressEntryID]) {
        do {
            try interactor.update(entries: entries, replacing: replacing)
        } catch {
            presentGenericError(message: error.localizedDescription)
        }
    }
}

// MARK: - AddressActionsOutput

extension AddressBookContactManagementViewModel: AddressActionsOutput {
    func addressActionsDidRequestCopy(_ group: AddressBookContactAddressGroup) {
        UIPasteboard.general.string = group.address

        let snackbar = TangemSnackbar(title: Localization.walletNotificationAddressCopied)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)
        Toast(view: snackbar).present(layout: .top(padding: 8), type: .temporary())
    }

    func addressActionsDidRequestEdit(_ group: AddressBookContactAddressGroup) {
        editAddress(group)
    }

    func addressActionsDidRequestRemove(_ group: AddressBookContactAddressGroup) {
        guard canDeleteContact, (entries?.addressCount ?? 0) <= 1 else {
            deleteAddress(entryIds: group.networks.map(\.id))
            return
        }

        // [REDACTED_TODO_COMMENT]
        // ("…last address of «[name]»…", Lokalise key pending) and an alert-vs-dialog style confirmed against the mockup.
        confirmationDialog = ConfirmationDialogViewModel(
            title: nil,
            subtitle: Localization.addressBookDeleteContactDescription,
            buttons: [
                .init(title: Localization.commonDelete, role: .destructive) { [weak self] in
                    guard let self else { return }
                    Task { await self.delete() }
                },
                .cancel,
            ]
        )
    }
}

// MARK: - Types

extension AddressBookContactManagementViewModel {
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
        let userWalletInfo: UserWalletInfo
        let isEditable: Bool

        var id: String { userWalletInfo.id.stringValue }
        var name: String { userWalletInfo.name }
        var supportedBlockchains: Set<BSDKBlockchain> { userWalletInfo.config.supportedBlockchains }
    }
}
