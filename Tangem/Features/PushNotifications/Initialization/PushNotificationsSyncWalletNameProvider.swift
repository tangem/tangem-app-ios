//
//  PushNotificationsSyncWalletNameProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

final class PushNotificationsSyncWalletNameProvider {
    // MARK: - Private Properties

    private let tangemApiService: TangemApiService
    private let userWalletRepository: UserWalletRepository

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        tangemApiService: TangemApiService,
        userWalletRepository: UserWalletRepository
    ) {
        self.tangemApiService = tangemApiService
        self.userWalletRepository = userWalletRepository
    }

    // MARK: - Implementation

    @MainActor
    func stopObserving() {
        bag.removeAll()
    }

    @MainActor
    func restartObserving() {
        bag.removeAll()

        userWalletRepository
            .models
            .map { userWalletModel in
                let context = userWalletModel.config
                    .contextBuilder
                    .enrich(withName: userWalletModel.name)
                    .build()

                return userWalletModel.updatePublisher
                    .compactMap(\.newName)
                    .map { (id: userWalletModel.userWalletId.stringValue, name: $0, context: context) }
            }
            .merge()
            .withWeakCaptureOf(self)
            .flatMap { service, result -> AnyPublisher<Void, Never> in
                service.updateRemoteWalletPublisher(
                    name: result.name,
                    context: result.context,
                    userWalletId: result.id
                )
            }
            .sink()
            .store(in: &bag)
    }

    private func updateRemoteWalletPublisher(
        name: String,
        context: some Encodable,
        userWalletId: String
    ) -> AnyPublisher<Void, Never> {
        Deferred {
            Future<Void, Never> { [weak self] promise in
                guard let self else {
                    promise(.success(()))
                    return
                }

                Task {
                    do {
                        try await self.tangemApiService.updateWallet(by: userWalletId, context: context)
                    } catch {
                        PushNotificationsSyncServiceLogger.error(
                            "Failed to sync wallet name for userWalletId: \(userWalletId), name: \(name)",
                            error: error
                        )
                    }

                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
