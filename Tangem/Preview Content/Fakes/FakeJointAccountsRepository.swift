//
//  FakeJointAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct FakeJointAccountsRepository: JointAccountsRepository {
    var jointAccounts: [StoredJointAccount] { [] }

    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func initialize() {}

    func loadJointAccountsFromRemote() async throws {}

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }

    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws {}

    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws {}

    func confirmJointAccount(withConfig config: JointAccountConfirmationConfig) async throws -> JointAccountStatus {
        throw "Joint accounts are not available in previews"
    }

    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite {
        throw "Joint accounts are not available in previews"
    }
}
