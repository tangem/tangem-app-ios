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

final class AddressBooksViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var selectedChipId: String?
    @Published private(set) var walletChips: [Chip] = []
    @Published private(set) var contentState: ContentState = .loading

    @Published private var debouncedQuery: String = ""

    var showsToolbarAddButton: Bool { contentState.hasContacts }

    // MARK: - Dependencies

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private weak var coordinator: AddressBooksRoutable?
    private let addressBooksProvider: any AddressBooksProvider
    private let addressBooksSubject: CurrentValueSubject<[AddressBookWallet], Never>
    private let matcher = AddressBookContactMatcher()
    private var bag = Set<AnyCancellable>()

    init(
        coordinator: AddressBooksRoutable,
        addressBooksProvider: any AddressBooksProvider = .common()
    ) {
        self.coordinator = coordinator
        self.addressBooksProvider = addressBooksProvider
        addressBooksSubject = .init(addressBooksProvider.addressBooks)
        selectedChipId = addressBooksSubject.value.count >= 2 ? Constants.allChipId : addressBooksSubject.value.first?.wallet.id.stringValue

        bindAddressBooks()
        bindSearchDebounce()
        bind()
    }

    func openAddContact() {
        guard let addContactTarget else {
            return
        }

        coordinator?.openAddContact(addressBookWallet: addContactTarget)
    }

    func retry() {
        let books = isAllScope ? addressBooksSubject.value : addressBooksSubject.value.filter { $0.wallet.id.stringValue == selectedChipId }
        Task {
            await withTaskGroup(of: Void.self) { group in
                for book in books {
                    group.addTask {
                        await book.addressBookManager.load()
                    }
                }
            }
        }
    }
}

// MARK: - Private

private extension AddressBooksViewModel {
    var isAllScope: Bool {
        selectedChipId == Constants.allChipId
    }

    var addContactTarget: AddressBookWallet? {
        if let selected = addressBooksSubject.value.first(where: { $0.wallet.id.stringValue == selectedChipId }) {
            return selected
        }

        if let currentId = userWalletRepository.selectedModel?.userWalletId.stringValue,
           let current = addressBooksSubject.value.first(where: { $0.wallet.id.stringValue == currentId }) {
            return current
        }

        return addressBooksSubject.value.first
    }

    static func effectiveScope(selected: String?, chips: [Chip], walletsWithContacts: [WalletState]) -> String? {
        if chips.isNotEmpty {
            if let selected, chips.contains(where: { $0.id == selected }) {
                return selected
            }
            return Constants.allChipId
        }

        return walletsWithContacts.count == 1 ? walletsWithContacts.first?.id : Constants.allChipId
    }

    func bindAddressBooks() {
        addressBooksProvider.addressBooksPublisher
            .dropFirst() // the subject is already seeded with the initial set
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
        let walletsWithContacts = wallets.filter { $0.contacts.isNotEmpty }
        let isMultiWallet = walletsWithContacts.count >= 2
        let query = live.isEmpty ? "" : settled
        let isSearching = live.isNotEmpty && live != settled

        let chips = makeChips(wallets: wallets, isMultiWallet: isMultiWallet, query: query)
        let scope = Self.effectiveScope(selected: selected, chips: chips, walletsWithContacts: walletsWithContacts)
        let scopeWallets = scope == Constants.allChipId ? wallets : wallets.filter { $0.id == scope }
        let content = makeContent(scopeWallets: scopeWallets, query: query, isSearching: isSearching)

        return ViewState(chips: chips, content: content, scope: scope)
    }

    func makeChips(wallets: [WalletState], isMultiWallet: Bool, query: String) -> [Chip] {
        guard isMultiWallet else {
            return []
        }

        let matching = wallets.filter { wallet in
            guard wallet.contacts.isNotEmpty else {
                return false
            }
            return query.isEmpty || matcher.filter(wallet.contacts, query: query).isNotEmpty
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
                guard let book else { return }
                self?.coordinator?.openEditContact(contact: contact, addressBookWallet: book)
            }
        }
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

        /// Whether this book's contacts can be shown. A network failure still surfaces the cached contacts,
        /// so it counts as ready only while there is something to show; a decode failure clears the cache and
        /// contributes nothing, yet is "done" rather than still loading.
        var isDisplayReady: Bool {
            switch syncState {
            case .synced, .failure(.decodingError): true
            case .failure(.networkError): contacts.isNotEmpty
            case .syncing, .failure(.updateRequired): false
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
