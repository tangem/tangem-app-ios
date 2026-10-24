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

    @Test("The campaign an AppsFlyer link names is written down as pending")
    func savesTheCampaignKeyOnArrival() async {
        await withReferralService { _ in
            let previousStorage = InjectedValues[\.tangemPayCampaignKeyStorage]
            InjectedValues[\.tangemPayCampaignKeyStorage] = TangemPayCampaignKeyStorageStub()
            defer { InjectedValues[\.tangemPayCampaignKeyStorage] = previousStorage }

            let recorder = IncomingActionRecorder()
            recorder.start()

            let manager = InjectedValues[\.incomingActionManager]
            let responder = CampaignReadingResponder()
            manager.becomeFirstResponder(responder)
            defer { manager.resignFirstResponder(responder) }

            handler.handleIncomingURL(Deeplink.campaign)

            #expect(responder.campaignKeyWhenAsked == "tpay_for_harvard123")
        }
    }

    @Test("What a link leaves behind is written by the time the chain is asked")
    func savesTheReferralBeforeTheChainIsAsked() async {
        await withReferralService { _ in
            let recorder = IncomingActionRecorder()
            recorder.start()

            let manager = InjectedValues[\.incomingActionManager]
            let responder = ReferralReadingResponder()
            manager.becomeFirstResponder(responder)
            defer { manager.resignFirstResponder(responder) }

            handler.handleIncomingURL(Deeplink.promoWithReferral)

            #expect(responder.refcodeWhenAsked == "friend")
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

            let manager = InjectedValues[\.incomingActionManager]
            let chainEnd = ClaimingResponder()
            manager.becomeFirstResponder(chainEnd)

            defer {
                manager.resignFirstResponder(chainEnd)
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

// MARK: - Spies

/// What a link has left behind, as seen from inside the chain — where a destination may be gated on it.
@MainActor
private final class ReferralReadingResponder: IncomingActionResponder {
    private(set) var refcodeWhenAsked: String?

    nonisolated func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        MainActor.assumeIsolated {
            refcodeWhenAsked = InjectedValues[\.referralService].refcode
            return true
        }
    }
}

private final class ClaimingResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        true
    }
}

@MainActor
private final class CampaignReadingResponder: IncomingActionResponder {
    private(set) var campaignKeyWhenAsked: String?

    nonisolated func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        MainActor.assumeIsolated {
            campaignKeyWhenAsked = TangemPayCampaignService().pendingCampaignKey
            return true
        }
    }
}
