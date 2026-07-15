//
//  AddressBooksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemUI
import TangemFoundation
import TangemLocalization

protocol AddressBooksSelectionOutput: AnyObject {
    func addressBooksDidSelect(_ group: AddressBookContactAddressGroup, of contact: AddressBookContact)
}

final class AddressBooksViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var selectedChipId: String?
    @Published private(set) var walletChips: [Chip] = []
    @Published private(set) var contentState: ContentState = .loading

    @Published private var debouncedQuery: String = ""

    var trailingToolbarButton: TrailingToolbarButton? {
        if selectionOutput != nil {
            return .close
        }

        return contentState.hasContacts ? .addContact : .none
    }

    // MARK: - Dependencies

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private weak var coordinator: AddressBooksRoutable?
    private weak var selectionOutput: AddressBooksSelectionOutput?
    private let addressBooksProvider: any AddressBooksProvider
    private let analyticsLogger: any AddressBookAnalyticsLogger
    private let addressBooksSubject: CurrentValueSubject<[AddressBookWallet], Never>
    private let matcher = AddressBookContactMatcher()
    private var bag = Set<AnyCancellable>()

    init(
        coordinator: AddressBooksRoutable,
        addressBooksProvider: any AddressBooksProvider,
        selectionOutput: AddressBooksSelectionOutput? = nil,
        analyticsLogger: any AddressBookAnalyticsLogger
    ) {
        self.coordinator = coordinator
        self.selectionOutput = selectionOutput
        self.addressBooksProvider = addressBooksProvider
        self.analyticsLogger = analyticsLogger
        addressBooksSubject = .init(addressBooksProvider.addressBooks)
        selectedChipId = addressBooksSubject.value.count >= 2 ? Constants.allChipId : addressBooksSubject.value.first?.wallet.id.stringValue

        bindAddressBooks()
        bindSearchDebounce()
        bind()
        loadAllAddressBooks()
    }

    func onFirstAppear() {
        let contactsCount = addressBooksSubject.value.reduce(0) { $0 + $1.addressBookManager.contacts.count }
        analyticsLogger.logContactListScreenOpened(walletId: analyticsWalletId, source: analyticsSource, contactsCount: contactsCount)
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    func openAddContact() {
        analyticsLogger.logAddContactTapped(walletId: analyticsWalletId, source: .settings)

        guard let addContactTarget else {
            return
        }

        coordinator?.openAddContact(addressBookWallet: addContactTarget)
    }

    func retry() {
        let books = isAllScope ? addressBooksSubject.value : addressBooksSubject.value.filter { $0.wallet.id.stringValue == selectedChipId }
        loadAddressBooks(books)
    }
}

// MARK: - Private

private extension AddressBooksViewModel {
    var analyticsWalletId: String {
        userWalletRepository.selectedModel?.userWalletId.stringValue ?? ""
    }

    var analyticsSource: AddressBookAnalyticsSource {
        selectionOutput != nil ? .sendFlow : .settings
    }

    var isAllScope: Bool {
        selectedChipId == Constants.allChipId
    }

    var addContactTarget: AddressBookWallet? {
        if let selected = addressBooksSubject.value.first(where: { $0.wallet.id.stringValue == selectedChipId }) {
            return selected
        }

        let books = addressBooksSubject.value.isNotEmpty ? addressBooksSubject.value : AllWalletsAddressBooksProvider().addressBooks

        if let currentId = userWalletRepository.selectedModel?.userWalletId.stringValue,
           let current = books.first(where: { $0.wallet.id.stringValue == currentId }) {
            return current
        }

        return books.first
    }

    static func effectiveScope(selected: String?, chips: [Chip], wallets: [WalletState]) -> String? {
        if chips.isNotEmpty {
            if let selected, chips.contains(where: { $0.id == selected }) {
                return selected
            }
            return Constants.allChipId
        }

        return wallets.count == 1 ? wallets.first?.id : Constants.allChipId
    }

    func loadAddressBooks(_ books: [AddressBookWallet]) {
        Task {
            await TaskGroup.executeKeepingOrder(items: books, action: { book in
                await book.addressBookManager.load()
            })
        }
    }

    func loadAllAddressBooks() {
        let managers = userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map(\.addressBookManager)

        Task {
            await TaskGroup.executeKeepingOrder(items: managers, action: { manager in
                await manager.load()
            })
        }
    }

    func bindAddressBooks() {
        addressBooksProvider.addressBooksPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, addressBooks in
                viewModel.addressBooksSubject.send(addressBooks)
            }
            .store(in: &bag)
    }

    func bindSearchDebounce() {
        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .assign(to: &$debouncedQuery)
    }

    func bind() {
        let liveQuery = $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()

        Publishers.CombineLatest4(allWalletsPublisher(), $selectedChipId, liveQuery, $debouncedQuery)
            .withWeakCaptureOf(self)
            .map { viewModel, input -> ViewState in
                let (wallets, selected, live, settled) = input
                return viewModel.makeViewState(wallets: wallets, selected: selected, live: live, settled: settled)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.walletChips = state.chips
                viewModel.contentState = state.content
                if viewModel.selectedChipId != state.scope {
                    viewModel.selectedChipId = state.scope
                }
            }
            .store(in: &bag)
    }

    func allWalletsPublisher() -> AnyPublisher<[WalletState], Never> {
        addressBooksSubject
            .flatMapLatest { addressBooks -> AnyPublisher<[WalletState], Never> in
                guard addressBooks.isNotEmpty else {
                    return .just(output: [WalletState]())
                }

                return addressBooks
                    .map { book in
                        Publishers.CombineLatest(book.addressBookPublisher, book.syncStatePublisher)
                            .map { contacts, syncState in
                                WalletState(id: book.wallet.id.stringValue, name: book.wallet.name, contacts: contacts, syncState: syncState, thumbnailType: book.wallet.config.walletThumbnailType)
                            }
                            .eraseToAnyPublisher()
                    }
                    .combineLatest()
            }
            .eraseToAnyPublisher()
    }

    func makeViewState(wallets: [WalletState], selected: String?, live: String, settled: String) -> ViewState {
        let query = live.isEmpty ? "" : settled
        let isSearching = live.isNotEmpty && live != settled

        let chips = makeChips(wallets: wallets, query: query)
        let scope = Self.effectiveScope(selected: selected, chips: chips, wallets: wallets)
        let scopeWallets = scope == Constants.allChipId ? wallets : wallets.filter { $0.id == scope }
        let content = makeContent(scopeWallets: scopeWallets, query: query, isSearching: isSearching)

        return ViewState(chips: chips, content: content, scope: scope)
    }

    func makeChips(wallets: [WalletState], query: String) -> [Chip] {
        let walletsWithContacts = wallets.filter { $0.contacts.isNotEmpty }

        guard walletsWithContacts.count >= 2 else {
            return []
        }

        let matching = walletsWithContacts.filter { wallet in
            query.isEmpty || matcher.filter(wallet.contacts, query: query).isNotEmpty
        }

        guard matching.isNotEmpty else {
            return []
        }

        return [Chip(id: Constants.allChipId, title: Localization.commonAll)]
            + matching.map { Chip(id: $0.id, title: $0.name, thumbnail: $0.thumbnailType) }
    }

    func makeContent(scopeWallets: [WalletState], query: String, isSearching: Bool) -> ContentState {
        let ready = scopeWallets.filter(\.isDisplayReady)

        guard ready.isNotEmpty else {
            if scopeWallets.isEmpty {
                return .empty
            }
            return scopeWallets.allSatisfy(\.isFailed) ? .failure : .loading
        }

        let contacts = ready.flatMap(\.contacts)

        guard contacts.isNotEmpty else {
            return .empty
        }

        if isSearching {
            return .searching
        }

        guard query.isNotEmpty else {
            return .results(makeContactViewModels(contacts))
        }

        let filtered = matcher.filter(contacts, query: query)
        return filtered.isEmpty ? .noResults : .results(makeContactViewModels(filtered))
    }

    func makeContactViewModels(_ contacts: [AddressBookContact]) -> [AddressBookContactViewModel] {
        let showsWalletName = Set(contacts.map { $0.walletId.stringValue }).count > 1

        return contacts.map { contact in
            let book = addressBooksSubject.value.first { $0.wallet.id.stringValue == contact.walletId.stringValue }
            let walletName = showsWalletName ? book?.wallet.name : nil

            return AddressBookContactViewModel(contact: contact, walletName: walletName) { [weak self] in
                self?.userDidTapOnContact(contact, in: book)
            }
        }
    }

    func userDidTapOnContact(_ contact: AddressBookContact, in book: AddressBookWallet?) {
        // In selection mode (opened from Send "View All") a tap resolves the contact's address and
        // returns it instead of editing the contact.
        if selectionOutput != nil {
            analyticsLogger.logContactSelected(walletId: contact.walletId.stringValue, contactId: contact.id.stringValue)
            let groups = contact.entries.groupedByAddress

            // A single-address contact is applied directly; a multi-address one opens the address picker.
            if let group = groups.singleElement {
                finishSelection(with: group, of: contact)
                return
            }

            coordinator?.openChooseAddress(contact: contact, output: self)

        } else if let book {
            coordinator?.openEditContact(contact: contact, addressBookWallet: book)
        }
    }

    func finishSelection(with group: AddressBookContactAddressGroup, of contact: AddressBookContact) {
        coordinator?.dismiss()
        selectionOutput?.addressBooksDidSelect(group, of: contact)
    }
}

// MARK: - ChooseAddressOutput

extension AddressBooksViewModel: ChooseAddressOutput {
    func chooseAddressDidSelect(_ group: AddressBookContactAddressGroup, of contact: AddressBookContact) {
        finishSelection(with: group, of: contact)
    }
}

// MARK: - Types

extension AddressBooksViewModel {
    enum ContentState {
        case loading
        case failure
        case empty
        case searching
        case results([AddressBookContactViewModel])
        case noResults

        var hasContacts: Bool {
            switch self {
            case .results, .noResults, .searching: true
            case .loading, .failure, .empty: false
            }
        }
    }

    enum TrailingToolbarButton {
        case close
        case addContact
    }
}

private extension AddressBooksViewModel {
    enum Constants {
        static let allChipId = "all"
    }

    struct ViewState {
        let chips: [Chip]
        let content: ContentState
        let scope: String?
    }

    struct WalletState {
        let id: String
        let name: String
        let contacts: [AddressBookContact]
        let syncState: AddressBookSyncState
        let thumbnailType: ThumbnailWalletViewType?

        /// Whether this book's contacts can be shown. A network failure or an in-flight re-sync still
        /// surfaces the cached contacts, so both count as ready only while there is something to show;
        /// a decode failure clears the cache and contributes nothing, yet is "done" rather than still loading.
        var isDisplayReady: Bool {
            switch syncState {
            case .synced, .failure(.decodingError): true
            case .syncing, .failure(.networkError): contacts.isNotEmpty
            case .failure(.updateRequired): false
            }
        }

        /// A book that can show nothing and won't recover on its own: an incompatible blob version, or a
        /// network failure with no cache to fall back on.
        var isFailed: Bool {
            switch syncState {
            case .failure(.updateRequired): true
            case .failure(.networkError): contacts.isEmpty
            case .syncing, .synced, .failure(.decodingError): false
            }
        }
    }
}
