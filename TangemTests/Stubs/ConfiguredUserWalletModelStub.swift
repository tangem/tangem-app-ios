//
//  ConfiguredUserWalletModelStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

final class ConfiguredUserWalletModelStub: UserWalletModelMock {
    private let stubbedConfig: UserWalletConfig

    init(config: UserWalletConfig) {
        stubbedConfig = config
    }

    override var config: UserWalletConfig { stubbedConfig }
}

// MARK: - Factories

extension ConfiguredUserWalletModelStub {
    static func mobile() -> UserWalletModel {
        var config = UserWalletConfigStub()
        config.unavailableFeatures = [.nfcInteraction]
        return ConfiguredUserWalletModelStub(config: config)
    }

    static func social() -> UserWalletModel {
        var config = UserWalletConfigStub()
        config.unavailableFeatures = [.nfcInteraction]
        config.hasSocialLogin = true
        return ConfiguredUserWalletModelStub(config: config)
    }

    static func card() -> UserWalletModel {
        ConfiguredUserWalletModelStub(config: UserWalletConfigStub())
    }

    static func mobile(count: Int) -> [UserWalletModel] {
        (0 ..< count).map { _ in mobile() }
    }

    static func cards(count: Int) -> [UserWalletModel] {
        (0 ..< count).map { _ in card() }
    }
}
