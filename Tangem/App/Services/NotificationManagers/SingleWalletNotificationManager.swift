//
//  SingleWalletNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class SingleTokenNotificationManager {
    private let walletModel: WalletModel
    private let isNoteWallet: Bool
    private weak var delegate: NotificationTapDelegate?

    private let notificationInputs: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []
    private var rentWarningTask: Task<String?, Error>?

    init(walletModel: WalletModel, isNoteWallet: Bool) {
        self.walletModel = walletModel
        self.isNoteWallet = isNoteWallet
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        bind()
    }

    private func bind() {
        bag = []

        walletModel
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .failed:
                    self?.setupNetworkUnreachable()
                case .noAccount(let message):
                    self?.setupNoAccountNotification(with: message)
                case .loading, .created:
                    break
                case .idle, .noDerivation:
                    self?.setupLoadedStateNotifications()
                }
            }
            .store(in: &bag)
    }

    private func setupLoadedStateNotifications() {
        let factory = NotificationsFactory()

        var events = [TokenNotificationEvent]()
        if let existentialWarning = walletModel.existentialDepositWarning {
            events.append(.existentialDepositWarning(message: existentialWarning))
        }

        if let sendBlockedReason = walletModel.sendBlockedReason {
            events.append(.event(for: sendBlockedReason))
        }

        let inputs = events.map {
            factory.buildNotificationInput(
                for: $0) { [weak self] id, actionType in
                    self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                } dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
        }

        Task { [weak self] in
            var inputs = inputs
            if let rentInput = await self?.loadRentNotificationIfNeeded() {
                inputs.append(rentInput)
            }

            await runOnMain {
                self?.notificationInputs.send(inputs)
            }
        }
    }

    private func setupNetworkUnreachable() {
        let factory = NotificationsFactory()
        notificationInputs
            .send([
                factory.buildNotificationInput(for: .networkUnreachable, dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }),
            ])
    }

    private func setupNoAccountNotification(with message: String) {
        let factory = NotificationsFactory()
        let currencySymbol = isNoteWallet ? nil : walletModel.blockchainNetwork.blockchain.currencySymbol
        let event = TokenNotificationEvent.noAccount(
            message: message,
            isNoteWallet: isNoteWallet,
            currencySymbol: currencySymbol
        )

        notificationInputs
            .send([
                factory.buildNotificationInput(
                    for: event,
                    buttonAction: { [weak self] id, actionType in
                        self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                    }, dismissAction: { [weak self] id in
                        self?.dismissNotification(with: id)
                    }
                ),
            ])
    }

    private func loadRentNotificationIfNeeded() async -> NotificationViewInput? {
        guard walletModel.hasRent else { return nil }

        rentWarningTask?.cancel()

        rentWarningTask = Task { await walletModel.updateRentWarning().async() }

        defer { rentWarningTask = nil }
        do {
            guard let rentMessage = try await rentWarningTask?.value else {
                return nil
            }

            let factory = NotificationsFactory()
            let input = factory.buildNotificationInput(for: .rentFee(rentMessage: rentMessage))
            return input
        } catch {
            AppLog.shared.debug("Failed to load rent warning: \(error)")
            return nil
        }
    }
}

extension SingleTokenNotificationManager: NotificationManager {
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputs.eraseToAnyPublisher()
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputs.value.removeAll(where: { $0.id == id })
    }
}
