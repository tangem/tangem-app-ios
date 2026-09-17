//
//  IncomingActionRecorderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("What a link leaves behind on arrival", .serialized)
@MainActor
struct IncomingActionRecorderTests {
    @Test("The referral a promo link carries is saved the moment the link arrives")
    func savesTheReferralOnArrival() async {
        await withReferralService { service in
            let recorder = IncomingActionRecorder()
            recorder.start()

            handler.handleIncomingURL(Deeplink.promoWithReferral)

            #expect(service.refcode == "friend")
            #expect(service.campaign == "spring")
        }
    }

    @Test("A promo link without a referral leaves nothing behind")
    func savesNothingWithoutRefcode() async {
        await withReferralService { service in
            let recorder = IncomingActionRecorder()
            recorder.start()

            handler.handleIncomingURL(Deeplink.promo)

            #expect(service.saveCallsCount == 0)
        }
    }

    @Test("The campaign an AppsFlyer link names is written down as pending", .enabled(if: FeatureProvider.isAvailable(.tangemPayCustomCards)))
    func savesTheCampaignKeyOnArrival() async {
        await withReferralService { _ in
            let previousPendingKey = AppSettings.shared.pendingTangemPayCampaignKey
            defer { AppSettings.shared.pendingTangemPayCampaignKey = previousPendingKey }
            AppSettings.shared.pendingTangemPayCampaignKey = nil

            let recorder = IncomingActionRecorder()
            recorder.start()

            handler.handleIncomingURL(Deeplink.campaign)

            #expect(AppSettings.shared.pendingTangemPayCampaignKey == "tpay_for_harvard123")
        }
    }

    @Test("A link that isn't a promo one is of no interest")
    func ignoresEverythingElse() async {
        await withReferralService { service in
            let recorder = IncomingActionRecorder()
            recorder.start()

            handler.handleIncomingURL(Deeplink.markets)

            #expect(service.saveCallsCount == 0)
        }
    }
}

// MARK: - Environment

private extension IncomingActionRecorderTests {
    var handler: IncomingActionHandler {
        InjectedValues[\.incomingActionHandler]
    }

    func withReferralService(_ body: (ReferralServiceStub) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousService = InjectedValues[\.referralService]
            let previousRepository = InjectedValues[\.userWalletRepository]

            let service = ReferralServiceStub()
            InjectedValues[\.referralService] = service
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])

            defer {
                InjectedValues[\.referralService] = previousService
                InjectedValues[\.userWalletRepository] = previousRepository
            }

            await body(service)
        }
    }

    enum Deeplink {
        static let promo = URL(string: "tangem://promo?promo_code=BTC2026")!
        static let promoWithReferral = URL(string: "tangem://promo?promo_code=BTC2026&ref=friend&campaign=spring")!
        static let markets = URL(string: "tangem://markets")!
        static let campaign = URL(string: "https://tangem.com/marketing?deep_link_value=tpay_for_harvard123")!
    }
}
