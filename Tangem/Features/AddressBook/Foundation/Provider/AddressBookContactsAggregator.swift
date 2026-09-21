//
//  AddressBookContactsAggregator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

enum AddressBookContactsAggregator {
    static func contactsPublisher() -> AnyPublisher<[AddressBookContact], Never> {
        let repository: UserWalletRepository = InjectedValues[\.userWalletRepository]

        return repository
            .eventProvider
            .filter(changesTheSetOfBooks)
            .mapToVoid()
            .prepend(())
            .flatMapLatest { _ in contactsPublisher(from: managers(from: repository)) }
            .eraseToAnyPublisher()
    }

    private static func contactsPublisher(from books: [AddressBookManager]) -> AnyPublisher<[AddressBookContact], Never> {
        guard books.isNotEmpty else {
            return .just(output: [])
        }

        return books
            .map(\.contactsPublisher)
            .combineLatest()
            .map { $0.flattened() }
            .eraseToAnyPublisher()
    }

    private static func changesTheSetOfBooks(_ event: UserWalletRepositoryEvent) -> Bool {
        switch event {
        case .locked, .unlocked, .inserted, .unlockedWallet, .deleted: true
        case .selected, .reordered: false
        }
    }

    private static func managers(from repository: UserWalletRepository) -> [AddressBookManager] {
        repository.models
            .filter { !$0.isUserWalletLocked }
            .map(\.addressBookManager)
    }
}
