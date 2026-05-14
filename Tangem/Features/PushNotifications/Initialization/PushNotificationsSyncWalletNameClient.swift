//
//  PushNotificationsSyncWalletNameClient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

final class PushNotificationsSyncWalletNameClient {
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
            .sink { service, result in
                service.updateRemoteWallet(
                    name: result.name,
                    context: result.context,
                    userWalletId: result.id
                )
            }
            .store(in: &bag)
    }

    func updateRemoteWallet(name: String, context: some Encodable, userWalletId: String) {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await tangemApiService.updateWallet(by: userWalletId, context: context)
            } catch {
                AppLogger.error(error: error)
            }
        }
    }
}
