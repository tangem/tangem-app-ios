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
    var receiveAssetsPublisher: AnyPublisher<[ReceiveAsset], Never> { get }
    var notificationsPublisher: AnyPublisher<[NotificationViewInput], Never> { get }

    func updateAssets()
}

struct CommonSelectorReceiveAssetsInteractor {
    // MARK: - Private Properties

    private let _receiveAssetsSubject: CurrentValueSubject<[ReceiveAsset], Never> = .init([])
    private let _receiveNotificationsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private let addressInfos: [ReceiveAddressInfo]
    private let notificationInputs: [NotificationViewInput]

    // MARK: - Init

    init(
        addressInfos: [ReceiveAddressInfo],
        notificationInputs: [NotificationViewInput] = []
    ) {
        self.addressInfos = addressInfos
        self.notificationInputs = notificationInputs
    }

    // MARK: - Public Implementation

    func updateAssets() {
        _receiveAssetsSubject.send([])
        _receiveNotificationsSubject.send(notificationInputs)

        setAddressInfosAssets()
        setDomainInfosAssets()
    }

    // MARK: - Private Implementation

    private func setAddressInfosAssets() {
        let addressAssets: [ReceiveAsset] = addressInfos.map { .address($0) }
        _receiveAssetsSubject.send(addressAssets)
    }

    // [REDACTED_TODO_COMMENT]
    private func setDomainInfosAssets() {
        runTask {
            await runOnMain {
                _receiveAssetsSubject.value.append(contentsOf: [])
            }
        }
    }
}

// MARK: - SelectorReceiveAssetsInteractor

extension CommonSelectorReceiveAssetsInteractor: SelectorReceiveAssetsInteractor {
    var receiveAssetsPublisher: AnyPublisher<[ReceiveAsset], Never> {
        _receiveAssetsSubject.eraseToAnyPublisher()
    }

    var notificationsPublisher: AnyPublisher<[NotificationViewInput], Never> {
        _receiveNotificationsSubject.eraseToAnyPublisher()
    }
}
