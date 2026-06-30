//
//  AddressBookRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol AddressBookRepository: AnyObject {
    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> { get }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { get }

    func ensureBookMutable() throws

    func load(silent: Bool) async
    func save(contacts: [AddressBookDecodedContact]) async throws
}
