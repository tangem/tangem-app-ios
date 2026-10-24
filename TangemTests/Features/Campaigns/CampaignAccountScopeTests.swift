//
//  CampaignAccountScopeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("CampaignAccountScope", .tags(.campaigns))
struct CampaignAccountScopeTests {
    private let cryptoAccount = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })
    private let jointAccount = CampaignJointAccountFixtures.makeJointAccount()

    @Test("The crypto scope leaves joint accounts out, the joint one takes them in")
    func accounts() {
        let manager = AccountModelsManagerStub(accounts: [.standard(.single(cryptoAccount)), .joint([jointAccount])])

        let cryptoScoped = CampaignAccountScope.crypto.accounts(from: manager)
        let jointScoped = CampaignAccountScope.cryptoAndJoint.accounts(from: manager)

        #expect(cryptoScoped.count == 1)
        #expect(cryptoScoped.first === cryptoAccount)
        #expect(jointScoped.count == 2)
        #expect(jointScoped.contains { $0 === jointAccount })
    }

    @Test("Adding a token in the crypto scope can't go to a joint account")
    func addTokenAccountFilter() {
        let filter = CampaignAccountScope.crypto.addTokenAccountFilter

        #expect(filter?(.init(account: cryptoAccount, supportedBlockchains: [])) == true)
        #expect(filter?(.init(account: jointAccount, supportedBlockchains: [])) == false)
        #expect(CampaignAccountScope.cryptoAndJoint.addTokenAccountFilter == nil)
    }
}
