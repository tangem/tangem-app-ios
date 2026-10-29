//
//  CommonInAppSurveySessionStoreTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonInAppSurveySessionStore")
struct CommonInAppSurveySessionStoreTests {
    private let walletA = UserWalletId(value: Data(repeating: 0xAA, count: 32))
    private let walletB = UserWalletId(value: Data(repeating: 0xBB, count: 32))

    @Test("A survey isn't completed until it is marked so")
    func notCompletedByDefault() async {
        let store = CommonInAppSurveySessionStore()

        #expect(await firstValue(of: store, userWalletId: walletA) == false)
    }

    @Test("Marking a survey completed counts only for that wallet")
    func completionIsPerWallet() async {
        let store = CommonInAppSurveySessionStore()

        store.markCompleted(surveyId: .demand, userWalletId: walletA)

        #expect(await firstValue(of: store, userWalletId: walletA) == true)
        #expect(await firstValue(of: store, userWalletId: walletB) == false)
    }

    @Test("A subscriber can mark another wallet's survey completed while it is told about one")
    func reentrantCompletion() async {
        let store = CommonInAppSurveySessionStore()
        let subscription = store.isCompletedPublisher(surveyId: .demand, userWalletId: walletA)
            .sink { [walletB] isCompleted in
                if isCompleted {
                    store.markCompleted(surveyId: .demand, userWalletId: walletB)
                }
            }

        store.markCompleted(surveyId: .demand, userWalletId: walletA)

        #expect(await firstValue(of: store, userWalletId: walletB) == true)
        withExtendedLifetime(subscription) {}
    }

    private func firstValue(of store: CommonInAppSurveySessionStore, userWalletId: UserWalletId) async -> Bool? {
        await store.isCompletedPublisher(surveyId: .demand, userWalletId: userWalletId).values.first { _ in true }
    }
}
