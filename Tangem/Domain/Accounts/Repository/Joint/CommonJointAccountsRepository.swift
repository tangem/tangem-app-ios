//
//  CommonJointAccountsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonJointAccountsRepository {
    private let userWalletId: UserWalletId
    private let networkService: JointAccountsNetworkService
    private let derivationInteractorFactory: JointAccountDerivationInteractorFactory
    private let persistentStorage: JointAccountsPersistentStorage

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: AnyPublisher<[StoredJointAccount], Never> = persistentStorage
        .didUpdatePublisher
        .prepend(()) // An initial value to trigger loading from storage
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.persistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        userWalletId: UserWalletId,
        networkService: JointAccountsNetworkService,
        derivationInteractorFactory: JointAccountDerivationInteractorFactory,
        persistentStorage: JointAccountsPersistentStorage
    ) {
        self.userWalletId = userWalletId
        self.networkService = networkService
        self.derivationInteractorFactory = derivationInteractorFactory
        self.persistentStorage = persistentStorage
    }
}

// MARK: - JointAccountsRepository protocol conformance

extension CommonJointAccountsRepository: JointAccountsRepository {
    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> {
        storageDidUpdatePublisher
    }

    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws -> JointAccountCreationResult {
        let payloadBuilder = JointAccountCreationPayloadBuilder(
            userWalletId: userWalletId,
            creationContext: config.creationContext
        )
        let interactor = derivationInteractorFactory.makeInteractor()

        let result = try await interactor.deriveAndSign(
            derivationIndex: config.derivationIndex,
            payloadBuilder: payloadBuilder
        )

        let blob = JointAccountCreationBlob(payload: result.payload, signature: result.signature)

        let creationResult = try await networkService.createJointAccount(blob: blob)
        try persistentStorage.appendNewOrUpdateExisting(creationResult.account)

        return creationResult
    }
}
