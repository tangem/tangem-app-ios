//
//  CommonHotAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonHotAccessCodeManager {
    @Injected(\.hotAccessCodeStorageManager) private var storageManager: HotAccessCodeStorageManager

    private lazy var stateManager = CommonHotAccessCodeStateManager(
        storage: self,
        validator: self,
        handler: self,
        configuration: .default
    )

    private let userWalletModel: UserWalletModel
    private weak var delegate: CommonHotAccessCodeManagerDelegate?

    init(userWalletModel: UserWalletModel, delegate: CommonHotAccessCodeManagerDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }
}

// MARK: - HotAccessCodeManager

extension CommonHotAccessCodeManager: HotAccessCodeManager {
    var statePublisher: AnyPublisher<HotAccessCodeState, Never> {
        stateManager.statePublisher
    }

    func validate(accessCode: String) throws {
        try stateManager.validate(accessCode: accessCode)
    }
}

// MARK: - HotAccessCodeStorage

extension CommonHotAccessCodeManager: HotAccessCodeStorage {
    func getWrongAccessCodeStore() -> HotWrongAccessCodeStore {
        storageManager.getWrongAccessCodeStore(userWalletId: userWalletModel.userWalletId)
    }

    func storeWrongAccessCodeAttempt(date: Date) {
        storageManager.storeWrongAccessCode(userWalletId: userWalletModel.userWalletId, date: date)
    }
}

// MARK: - HotAccessCodeValidator

extension CommonHotAccessCodeManager: HotAccessCodeValidator {
    func isValid(accessCode: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        accessCode == "111111"
    }
}

// MARK: - HotAccessCodeHandler

extension CommonHotAccessCodeManager: HotAccessCodeHandler {
    func handleAccessCodeSuccessful() {
        storageManager.clearWrongAccessCode(userWalletId: userWalletModel.userWalletId)
        delegate?.handleAccessCodeSuccessful(userWalletModel: userWalletModel)
    }

    func handleAccessCodeDelete() {
        storageManager.clearWrongAccessCode(userWalletId: userWalletModel.userWalletId)
        delegate?.handleAccessCodeDelete(userWalletModel: userWalletModel)
    }
}
