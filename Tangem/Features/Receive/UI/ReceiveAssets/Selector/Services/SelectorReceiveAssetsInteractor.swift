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

    func hasDomainNameAddresses() -> Bool
}

class CommonSelectorReceiveAssetsInteractor {
    // MARK: - Private Properties

    private let _addressTypesSubject: CurrentValueSubject<[ReceiveAddressType], Never>
    private let _notificationsSubject: CurrentValueSubject<[NotificationViewInput], Never>
    private var addressTypesSubscription: AnyCancellable?

    // MARK: - Init

    init(
        addressTypesProvider: ReceiveAddressTypesProvider,
        notificationInputs: [NotificationViewInput]
    ) {
        _addressTypesSubject = .init([])
        _notificationsSubject = .init(notificationInputs)
        bind(to: addressTypesProvider)
    }

    private func bind(to addressTypesProvider: ReceiveAddressTypesProvider) {
        addressTypesSubscription = addressTypesProvider
            .receiveAddressTypesPublisher
            .subscribe(_addressTypesSubject)
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

    func hasDomainNameAddresses() -> Bool {
        let currentAddressTypes = _addressTypesSubject.value

        return currentAddressTypes.contains(where: { $0.id.hasPrefix(ReceiveAddressType.Key.domain.rawValue) })
    }
}
