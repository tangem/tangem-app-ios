//
//  JointAccountOperationRecipientSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol JointAccountOperationRecipientSource {
    var contacts: [AddressBookContact] { get }
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> { get }
    var isAddressBookSyncedPublisher: AnyPublisher<Bool, Never> { get }
    var tangemPayDepositOwnersPublisher: AnyPublisher<[TangemPayDepositOwner], Never> { get }
}

struct CommonJointAccountOperationRecipientSource {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let addressBookWallet: AddressBookWallet

    init(addressBookWallet: AddressBookWallet) {
        self.addressBookWallet = addressBookWallet
    }
}

// MARK: - JointAccountOperationRecipientSource

extension CommonJointAccountOperationRecipientSource: JointAccountOperationRecipientSource {
    var contacts: [AddressBookContact] {
        addressBookWallet.addressBookManager.contacts
    }

    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        AddressBookContactsAggregator.contactsPublisher()
    }

    var isAddressBookSyncedPublisher: AnyPublisher<Bool, Never> {
        addressBookWallet.syncStatePublisher
            .map(\.isSynced)
            .eraseToAnyPublisher()
    }

    var tangemPayDepositOwnersPublisher: AnyPublisher<[TangemPayDepositOwner], Never> {
        TangemPayDepositOwnersPublisherFactory
            .makePublisher(userWalletRepository: userWalletRepository)
            .eraseToAnyPublisher()
    }
}
