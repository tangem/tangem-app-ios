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
    @Published private(set) var nameError: String?

    @Published private(set) var isProcessing: Bool = false

    @Published var alert: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    @Published private var entries: AddressBookContactDraftEntries?
    @Published private var canAddNewAddress: Bool = true

    let title: String
    let mainButtonTitle: String
    let focusesNameOnFirstAppear: Bool

    var maxNameLength: Int { AddressBookContactNameValidator.maxLength }

    let colors: [GridItemColor] = AccountModel.CompositeIcon.Color
        .allCases
        .map { iconColor in
            GridItemColor(id: iconColor, color: CompositeIconColorPalette.color(for: iconColor))
        }

    @Published private(set) var addressesSection: [AddressRowType] = []

    var iconViewData: AccountIconView.ViewData {
        .composite(
            backgroundColor: CompositeIconColorPalette.color(for: selectedColor.id),
            nameMode: nameMode
        )
    }

    // MARK: - Dependencies

    private let interactor: AddressBookContactManagementInteractor
    private let addressBooksProvider: any AddressBooksProvider
    private weak var coordinator: AddressBookContactManagementRoutable?
    private var bag = Set<AnyCancellable>()

    private var nameMode: AccountIconView.NameMode {
        if let firstLetter = contactName.trimmed().first {
            return .letter(String(firstLetter))
        }

        return .letter("N")
    }

    init(
        interactor: AddressBookContactManagementInteractor,
        coordinator: AddressBookContactManagementRoutable,
        addressBooksProvider: any AddressBooksProvider,
        focusesNameOnFirstAppear: Bool = false
    ) {
        self.interactor = interactor
        self.addressBooksProvider = addressBooksProvider
        self.coordinator = coordinator
        self.focusesNameOnFirstAppear = focusesNameOnFirstAppear

        title = interactor.title
        mainButtonTitle = interactor.mainButtonTitle

        let newColor = CompositeIconColor.randomElement()
        selectedColor = GridItemColor(
            id: newColor,
            color: CompositeIconColorPalette.color(for: newColor)
        )

        bind()
        loadAddressBooks()
    }

    func userDidRequestDismiss() {
        guard !isProcessing, interactor.hasUnsavedChanges else {
            coordinator?.dismissContactManagement()
            return
        }

        alert = AlertBuilder.makeExitAlert(
            title: Localization.addressBookUnsavedChanges,
            message: Localization.addressBookUnsavedChangesDescription,
            keepEditingButtonText: Localization.addressBookKeepEditing,
            discardButtonText: Localization.addressBookDiscard,
            discardAction: { [weak self] in
                self?.coordinator?.dismissContactManagement()
            }
        )
    }

    func userDidRequestWalletChange() {
        guard let selectedWallet, let coordinator else {
            return
        }

        let addressBookWallets = addressBooksProvider.addressBooks
            .filter { $0.wallet.id != selectedWallet.userWalletInfo.id }

        guard addressBookWallets.isNotEmpty else {
            return
        }

        let viewModel = AddressBookWalletPickerViewModel(
            addressBookWallets: addressBookWallets,
            output: self,
            routable: coordinator
        )
        coordinator.presentWalletPicker(viewModel)
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
    func loadAddressBooks() {
        let books = addressBooksProvider.addressBooks
        Task {
            await withTaskGroup(of: Void.self) { group in
                for book in books {
                    group.addTask {
                        await book.addressBookManager.load(silent: true)
                    }
                }
            }
        }
    }

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
            .map { color in GridItemColor(id: color, color: CompositeIconColorPalette.color(for: color)) }
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
            .withWeakCaptureOf(self)
            .map { viewModel, addressBookWallet -> WalletRowType? in
                WalletRowType(
                    userWalletInfo: addressBookWallet.wallet,
                    isEditable: viewModel.addressBooksProvider.addressBooks.count > 1
                )
            }
            .receiveOnMain()
            .assign(to: &$selectedWallet)

        interactor.possibleToAddNewAddress
            .receiveOnMain()
            .assign(to: &$canAddNewAddress)

        interactor.possibleToDeleteContact
            .receiveOnMain()
            .assign(to: &$canDeleteContact)

        let nameValidationErrorPublisher = $contactName
            .map { AddressBookContactNameValidator().validationError(in: $0) }
            .removeDuplicates()

        interactor.isMainButtonEnabledPublisher
            .combineLatest(nameValidationErrorPublisher)
            .map { isEnabled, nameValidationError in isEnabled && nameValidationError == nil }
            .receiveOnMain()
            .assign(to: &$isMainButtonEnabled)

        Publishers.CombineLatest3(nameValidationErrorPublisher, interactor.isNameTakenPublisher, $isProcessing)
            .map { nameValidationError, isNameTaken, isProcessing -> String? in
                guard !isProcessing else { return nil }

                switch nameValidationError {
                case .nameContainsForbiddenCharacters?: return Localization.addressBookNameInvalidCharsError
                case .nameTooLong?: return Localization.addressBookNameMaxCharsError
                default: return isNameTaken ? Localization.addressBookNameTakenError : nil
                }
            }
            .receiveOnMain()
            .assign(to: &$nameError)

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

        types.append(.addNewAddress(AddressBookContactAddNewAddressRowViewModel(isEnabled: canAddNewAddress, action: { [weak self] in
            guard let self else { return }

            if canAddNewAddress {
                addNewAddress()
            } else {
                showMaxAddressesAlert()
            }
        })))

        return types
    }

    func addNewAddress() {
        guard let wallet = selectedWallet else {
            return
        }

        coordinator?.openAddAddress(userWalletInfo: wallet.userWalletInfo, output: self, options: .add, reservedContacts: interactor.reservedContacts)
    }

    func showMaxAddressesAlert() {
        alert = AlertBinder(
            title: Localization.addressBookMaxNetworksAlertTitle,
            message: Localization.addressBookMaxNetworksAlertDescription
        )
    }

    func editAddress(_ group: AddressBookContactAddressGroup) {
        guard let wallet = selectedWallet else {
            return
        }

        coordinator?.openAddAddress(
            userWalletInfo: wallet.userWalletInfo,
            output: self,
            options: .edit(
                address: group.address,
                memo: group.memo,
                networks: Set(group.networks.map(\.blockchain)),
                replacing: group.networks.map(\.id)
            ),
            reservedContacts: interactor.reservedContacts
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

        do {
            try await interactor.save()
            coordinator?.dismissContactManagement()
        } catch AddressBookValidationError.addressAlreadySaved(let contactName) {
            isProcessing = false
            presentGenericError(message: Localization.addressBookAddressTakenError(contactName))
        } catch {
            isProcessing = false
            guard !error.isCancellationError else { return }

            presentGenericError(title: Localization.commonSomethingWentWrong, message: interactor.saveErrorMessage ?? error.localizedDescription)
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

            presentGenericError(title: Localization.commonSomethingWentWrong, message: Localization.addressBookDeletingError)
        }
    }

    func presentGenericError(title: String = Localization.commonError, message: String) {
        alert = AlertBinder(title: title, message: message)
    }
}

// MARK: - AddressBookAddAddressOutput

extension AddressBookContactManagementViewModel: AddressBookAddAddressOutput {
    var contactHasUnsavedChanges: Bool {
        interactor.hasUnsavedChanges
    }

    func userDidAddAddress(entries: [AddressBookEntryDraft], replacing: [AddressBookAddressEntryID]) {
        do {
            try interactor.update(entries: entries, replacing: replacing)
        } catch {
            presentGenericError(message: error.localizedDescription)
        }
    }
}

// MARK: - AddressBookWalletPickerOutput

extension AddressBookContactManagementViewModel: AddressBookWalletPickerOutput {
    func walletPickerDidSelect(_ addressBookWallet: AddressBookWallet) {
        interactor.update(addressBookWallet: addressBookWallet)
    }
}

// MARK: - AddressActionsOutput

extension AddressBookContactManagementViewModel: AddressActionsOutput {
    func addressActionsDidRequestCopy(_ group: AddressBookContactAddressGroup) {
        UIPasteboard.general.string = group.address

        let snackbar = TangemSnackbar(title: Localization.addressBookAddressCopied)
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

        confirmationDialog = ConfirmationDialogViewModel(
            title: nil,
            subtitle: Localization.addressBookDeleteLastAddress(contactName.trimmed()),
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
