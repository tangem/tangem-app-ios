//
//  ReferralBindingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Referral binding", .serialized)
@MainActor
struct ReferralBindingTests {
    @Test("A referral arriving before there is a wallet is written down and stays owed a binding")
    func savedReferralWithoutWalletStaysOwed() async {
        await withSettings {
            let service = CommonReferralService()

            service.saveAndBindIfNeeded(refcode: Constants.refcode, campaign: nil)

            #expect(AppSettings.shared.referralRefcode == Constants.refcode)
            #expect(AppSettings.shared.hasReferralBindingRequest)
        }
    }

    @Test("Another referral arriving while one is owed changes nothing")
    func anotherArrivalChangesNothing() async {
        await withSettings {
            let service = CommonReferralService()

            service.saveAndBindIfNeeded(refcode: Constants.refcode, campaign: nil)
            service.saveAndBindIfNeeded(refcode: "OTHER", campaign: nil)

            #expect(AppSettings.shared.referralRefcode == Constants.refcode)
            #expect(AppSettings.shared.hasReferralBindingRequest)
        }
    }

    @Test("A referral that has been bound is not bound again")
    func boundReferralIsLeftAlone() async {
        await withSettings {
            let service = CommonReferralService()

            service.saveAndBindIfNeeded(refcode: Constants.refcode, campaign: nil)
            AppSettings.shared.hasReferralBindingRequest = false

            service.saveAndBindIfNeeded(refcode: Constants.refcode, campaign: nil)

            #expect(!AppSettings.shared.hasReferralBindingRequest)
        }
    }

    @Test("A referral left unreadable by an older build does not hold its owed binding against a real one")
    func unreadableStoredReferralIsReplaced() async {
        await withSettings {
            let service = CommonReferralService()

            AppSettings.shared.referralRefcode = "null"
            AppSettings.shared.hasReferralBindingRequest = true

            service.saveAndBindIfNeeded(refcode: Constants.refcode, campaign: nil)

            #expect(AppSettings.shared.referralRefcode == Constants.refcode)
            #expect(AppSettings.shared.hasReferralBindingRequest)
        }
    }

    private func withSettings(_ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousRefcode = AppSettings.shared.referralRefcode
            let previousCampaign = AppSettings.shared.referralCampaign
            let previousRequest = AppSettings.shared.hasReferralBindingRequest

            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])
            AppSettings.shared.referralRefcode = nil
            AppSettings.shared.referralCampaign = nil
            AppSettings.shared.hasReferralBindingRequest = false

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                AppSettings.shared.referralRefcode = previousRefcode
                AppSettings.shared.referralCampaign = previousCampaign
                AppSettings.shared.hasReferralBindingRequest = previousRequest
            }

            await body()
        }
    }

    private enum Constants {
        static let refcode = "REFCODE"
    }
}
