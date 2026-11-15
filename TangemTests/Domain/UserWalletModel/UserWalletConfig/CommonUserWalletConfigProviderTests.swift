//
//  CommonUserWalletConfigProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for the config `CommonUserWalletConfigProvider` hands out")
struct CommonUserWalletConfigProviderTests {
    // MARK: - Private properties

    private let ethereum = Blockchain.ethereum(testnet: false)
    private let hedera = Blockchain.hedera(curve: .ed25519_slip0010, testnet: false)

    // MARK: - Tests

    @Test("Before a wallet model is configured, the config the provider was created with is handed out")
    func initialConfigBeforeConfiguration() {
        let sut = CommonUserWalletConfigProvider(config: UserWalletConfigStub(supportedBlockchains: [ethereum]))

        #expect(sut.config.supportedBlockchains == [ethereum])
    }

    @Test("Once configured, the wallet model's current config is handed out, also after the model's config changes")
    func modelConfigAfterConfiguration() {
        let userWalletModel = UserWalletModelConfigStub(config: UserWalletConfigStub(supportedBlockchains: [ethereum]))
        let sut = CommonUserWalletConfigProvider(config: UserWalletConfigStub(supportedBlockchains: [ethereum]))

        sut.configure(userWalletModel: userWalletModel)
        userWalletModel.currentConfig = UserWalletConfigStub(supportedBlockchains: [ethereum, hedera])

        withExtendedLifetime(userWalletModel) {
            #expect(sut.config.supportedBlockchains == [ethereum, hedera])
        }
    }
}

// MARK: - Stubs

private final class UserWalletModelConfigStub: UserWalletModelMock {
    var currentConfig: UserWalletConfig

    init(config: UserWalletConfig) {
        currentConfig = config
        super.init()
    }

    override var config: UserWalletConfig { currentConfig }
}
