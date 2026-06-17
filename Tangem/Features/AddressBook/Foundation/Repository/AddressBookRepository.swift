//
//  AddressBookRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Owns one wallet's encrypted address book: network sync, the local encrypted cache, and AES-GCM
/// encrypt/decrypt. It publishes *decoded* (not yet verified) contacts — signature verification is
/// the manager's responsibility.
protocol AddressBookRepository: AnyObject {
    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> { get }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { get }

    func load() async
    func save(contacts: [AddressBookDecodedContact]) async throws
}
