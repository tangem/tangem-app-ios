//
//  CommonAddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The heart of address book management: orchestrates the local repository and the remote network service.
/// It pulls the remote version, compares it with the local one, and decides what to do next.
actor CommonAddressBookManager {
    private let repository: AddressBookRepository
    private let networkService: AddressBookNetworkService

    private var syncTask: Task<Void, Never>?

    init(repository: AddressBookRepository, networkService: AddressBookNetworkService) {
        self.repository = repository
        self.networkService = networkService
    }

    // MARK: - Sync (remote -> local)

    private func performSync() async {
        do {
            let remoteInfo = try await networkService.getAddressBook(retryCount: 0)
            try Task.checkCancellation()
            try await applyIfNewer(remoteInfo)
        } catch AddressBookNetworkServiceError.notImplemented {
            // No remote API yet — keep the local state as the source of truth.
            currentSynchronizerState = .idle
        } catch {
            currentSynchronizerState = .idle
        }
    }

    /// Replaces the local copy only when the remote version differs from the local one.
    private func applyIfNewer(_ remoteInfo: RemoteAddressBookInfo) async throws {
        guard await remoteInfo.version != repository.localVersion else {
            return
        }

        try await repository.save(addressBook: remoteInfo.addressBook, version: remoteInfo.version)
    }

    // MARK: - Commit (local -> remote, remote-first)

    /// Pushes the address book to the server first; the local copy is updated only after a successful remote write.
    private func commit(_ addressBook: AddressBook) async throws {
        do {
            let localVersion = await repository.localVersion
            let remoteInfo = try await networkService.saveAddressBook(
                addressBook,
                version: localVersion,
                retryCount: 0
            )
            try Task.checkCancellation()
            try await repository.save(addressBook: remoteInfo.addressBook, version: remoteInfo.version)
        } catch AddressBookNetworkServiceError.missingRevision, AddressBookNetworkServiceError.inconsistentState {
            try await refreshInconsistentState()
            try Task.checkCancellation()
            try await commit(addressBook)
        } catch AddressBookNetworkServiceError.notImplemented {
            // No remote API yet — persist locally so the feature works offline.
            try await repository.save(addressBook: addressBook, version: nil)
        } catch AddressBookNetworkServiceError.underlyingError(let error) {
            throw error
        }
    }

    /// Refreshes the local state (and the revision) from the server before retrying a conflicting commit.
    private func refreshInconsistentState() async throws {
        let remoteInfo = try await networkService.getAddressBook(retryCount: Constants.maxRetryCount)
        try await repository.save(addressBook: remoteInfo.addressBook, version: remoteInfo.version)
    }
}

// MARK: - AddressBookManager

extension CommonAddressBookManager: AddressBookManager {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> {
        repository.addressBookPublisher
    }

    func save(contact: AddressBookContact) async throws {
        var addressBook = try await repository.getAddressBook()

        if let index = addressBook.firstIndex(where: { $0.id == contact.id }) {
            addressBook[index] = contact
        } else {
            addressBook.append(contact)
        }

        try await commit(addressBook)
    }

    func remove(contact: AddressBookContact) async throws {
        var addressBook = try await repository.getAddressBook()
        addressBook.removeAll { $0.id == contact.id }
        try await commit(addressBook)
    }
}

// MARK: - Constants

private extension CommonAddressBookManager {
    enum Constants {
        static let maxRetryCount = 3
    }
}
