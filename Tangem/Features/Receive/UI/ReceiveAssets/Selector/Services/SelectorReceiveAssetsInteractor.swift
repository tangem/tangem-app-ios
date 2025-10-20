//
//  SelectorReceiveAssetsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol SelectorReceiveAssetsInteractor {
    var addressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> { get }
    var notificationsPublisher: AnyPublisher<[NotificationViewInput], Never> { get }

    func update()
    func hasDomainNameAddresses() -> Bool
}

class CommonSelectorReceiveAssetsInteractor {
    // MARK: - Private Properties

    private let _addressTypesSubject: CurrentValueSubject<[ReceiveAddressType], Never> = .init([])
    private let _notificationsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private let notificationInputs: [NotificationViewInput]
    private let addressTypes: [ReceiveAddressType]

    // MARK: - Init

    init(notificationInputs: [NotificationViewInput] = [], addressTypes: [ReceiveAddressType]) {
        self.notificationInputs = notificationInputs
        self.addressTypes = addressTypes
    }
}

// MARK: - SelectorReceiveAssetsInteractor

extension CommonSelectorReceiveAssetsInteractor: SelectorReceiveAssetsInteractor {
    var addressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> {
        _addressTypesSubject.eraseToAnyPublisher()
    }

    var notificationsPublisher: AnyPublisher<[NotificationViewInput], Never> {
        _notificationsSubject.eraseToAnyPublisher()
    }

    func update() {
        _addressTypesSubject.send(addressTypes)
        _notificationsSubject.send(notificationInputs)
    }

    func hasDomainNameAddresses() -> Bool {
        let currentAddressTypes = _addressTypesSubject.value

        return currentAddressTypes.contains(where: { $0.id.hasPrefix(ReceiveAddressType.Key.domain.rawValue) })
    }
}
