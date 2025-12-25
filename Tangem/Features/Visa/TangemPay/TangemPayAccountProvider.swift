//
//  TangemPayAccountProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

// [REDACTED_TODO_COMMENT]
// Remove it and setup it before UserWalletModel was created
protocol TangemPayAccountProviderSetupable: TangemPayAccountProvider {
    func setup(for userWalletModel: any UserWalletModel)
}

protocol TangemPayAccountProvider {
    var tangemPayAccount: TangemPayAccount? { get }
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> { get }
}

class CommonTangemPayAccountProvider {
    private let tangemPayAccountSubject: CurrentValueSubject<TangemPayAccount?, Never> = .init(nil)
    private let onKYCCancelledSubject = PassthroughSubject<Void, Never>()
    private var bag = Set<AnyCancellable>()

    init() {}
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProviderSetupable {
    func setup(for userWalletModel: any UserWalletModel) {
        Task { [self] in
            if await !(AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[
                userWalletModel.userWalletId.stringValue
            ] ?? false) {
                let builder = TangemPayAccountBuilder()
                let tangemPayAccount = try? await builder.makeTangemPayAccount(
                    authorizerType: .availabilityService,
                    userWalletModel: userWalletModel
                )

                if let tangemPayAccount {
                    tangemPayAccount.setupKYCCancellationDelegate(self)
                    tangemPayAccountSubject.send(tangemPayAccount)
                }
            }

            userWalletModel.updatePublisher
                .compactMap(\.tangemPayAccount)
                .handleEvents(receiveOutput: { [weak self] account in
                    guard let self else { return }
                    account.setupKYCCancellationDelegate(self)
                })
                .sink(receiveValue: tangemPayAccountSubject.send)
                .store(in: &bag)

            userWalletModel.updatePublisher
                .filter { $0.isKYCDeclined }
                .sink { [weak self] _ in
                    self?.tangemPayAccountSubject.send(nil)
                }
                .store(in: &bag)

            onKYCCancelledSubject
                .map { UpdateRequest.tangemPayKYCDeclined }
                .sink { [weak userWalletModel] in
                    userWalletModel?.update(type: $0)
                }
                .store(in: &bag)
        }
    }
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProvider {
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> {
        tangemPayAccountSubject.eraseToAnyPublisher()
    }

    var tangemPayAccount: TangemPayAccount? {
        tangemPayAccountSubject.value
    }
}

// MARK: - TangemPayKYCCancellationDelegate

extension CommonTangemPayAccountProvider: TangemPayKYCCancellationDelegate {
    func onKYCCancelled() {
        onKYCCancelledSubject.send()
    }
}

// MARK: - Private utils

private extension UpdateResult {
    var isKYCDeclined: Bool {
        switch self {
        case .tangemPayKYCDeclined:
            return true
        default:
            return false
        }
    }
}
