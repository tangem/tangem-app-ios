//
//  MarketingActivityLinkRecorderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Recording a marketing activity uid on link arrival", .serialized)
@MainActor
struct MarketingActivityLinkRecorderTests {
    private let bindingService = MarketingActivityBindingServiceSpy()

    @Test("A link to a destination of ours registers its uid once")
    func registersOnArrival() async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(Deeplink.marketsWithUid)

            #expect(bindingService.registeredUids == ["AbC-123"])
        }
    }

    @Test("Handing the link back to the chain doesn't register it again")
    func redeliveryDoesNotRegister() async {
        await withRepository {
            let manager = makeManager()
            var arrived: IncomingAction?
            let cancellable = manager.incomingActionsPublisher.sink { arrived = $0 }
            defer { cancellable.cancel() }

            manager.handleIncomingURL(Deeplink.marketsWithUid)
            if let arrived {
                manager.deliver(arrived)
                manager.deliver(arrived)
            }

            #expect(arrived != nil)
            #expect(bindingService.registeredUids == ["AbC-123"])
        }
    }

    @Test("Opening the same link again registers it again")
    func reopeningRegistersAgain() async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(Deeplink.marketsWithUid)
            manager.handleIncomingURL(Deeplink.marketsWithUid)

            #expect(bindingService.registeredUids == ["AbC-123", "AbC-123"])
        }
    }

    @Test(
        "A link that names no destination of ours registers nothing",
        arguments: [Deeplink.unknownHostWithUid, Deeplink.ownPageWithUid]
    )
    func ignoresOtherLinks(link: URL) async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(link)

            #expect(bindingService.registeredUids.isEmpty)
        }
    }

    @Test(
        "A link to a destination of ours registers its uid even when the destination turns it down",
        arguments: [Deeplink.tokenWithoutParametersWithUid, Deeplink.payAppPageWithoutIdWithUid, Deeplink.uppercaseSchemeWithUid]
    )
    func registersRejectedDestinations(link: URL) async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(link)

            #expect(bindingService.registeredUids == ["AbC-123"])
        }
    }

    @Test(
        "A OneLink naming a uid in deep_link_sub3 leaves it to AppsFlyer",
        arguments: [Deeplink.oneLinkWithSub3, Deeplink.brandedOneLinkWithSub3, Deeplink.uppercaseOneLinkWithSub3]
    )
    func leavesSub3OneLinksToAppsFlyer(link: URL) async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(link)

            #expect(bindingService.registeredUids.isEmpty)
        }
    }

    @Test(
        "A OneLink without a uid in deep_link_sub3 registers the uid it carries",
        arguments: [Deeplink.oneLinkWithUid, Deeplink.oneLinkWithEmptySub3]
    )
    func registersOneLinkUidWithoutSub3(link: URL) async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(link)

            #expect(bindingService.registeredUids == ["AbC-123"])
        }
    }

    @Test("A link without a uid registers nothing")
    func ignoresLinksWithoutUid() async {
        await withRepository {
            let manager = makeManager()

            manager.handleIncomingURL(Deeplink.markets)

            #expect(bindingService.registeredUids.isEmpty)
        }
    }

    @Test(
        "A push carrying a link to a destination of ours registers its uid",
        arguments: [
            ["deeplink": "tangem://markets?uid=AbC-123"],
            ["link": "tangem://markets?uid=AbC-123"],
            Push.paymentWithLink("tangem://markets?uid=AbC-123"),
        ]
    )
    func pushLinkRegisters(userInfo: [String: String]) async {
        await withRepository {
            let manager = makeManager()

            manager.handlePush(userInfo: userInfo)

            #expect(bindingService.registeredUids == ["AbC-123"])
        }
    }

    @Test("A payment push doesn't register the uid of a link that names nothing of ours")
    func paymentPushIgnoresForeignLink() async {
        await withRepository {
            let manager = makeManager()

            manager.handlePush(userInfo: Push.paymentWithLink("https://example.com/page?uid=AbC-123"))

            #expect(bindingService.registeredUids.isEmpty)
        }
    }
}

// MARK: - Helpers

private extension MarketingActivityLinkRecorderTests {
    enum Deeplink {
        static let markets = URL(string: "tangem://markets")!
        static let marketsWithUid = URL(string: "tangem://markets?uid=AbC-123")!
        static let unknownHostWithUid = URL(string: "tangem://abc?uid=AbC-123")!
        static let ownPageWithUid = URL(string: "https://tangem.com/some/page?uid=AbC-123")!
        static let tokenWithoutParametersWithUid = URL(string: "tangem://token?uid=AbC-123")!
        static let payAppPageWithoutIdWithUid = URL(string: "https://tangem.com/pay-app?uid=AbC-123")!
        static let uppercaseSchemeWithUid = URL(string: "Tangem://markets?uid=AbC-123")!
        static let oneLinkWithUid = URL(string: "https://tangem.onelink.me/AbCd?deep_link_value=tpay_mobileonboard&uid=AbC-123")!
        static let oneLinkWithEmptySub3 = URL(string: "https://tangem.onelink.me/AbCd?deep_link_value=tpay_mobileonboard&deep_link_sub3=&uid=AbC-123")!
        static let oneLinkWithSub3 = URL(string: "https://tangem.onelink.me/AbCd?deep_link_value=tpay_mobileonboard&deep_link_sub3=AbC-123&uid=AbC-123")!
        static let brandedOneLinkWithSub3 = URL(string: "https://join.tangem.com/AbCd?deep_link_value=tpay_for_some-campaign&deep_link_sub3=AbC-123&uid=AbC-123")!
        static let uppercaseOneLinkWithSub3 = URL(string: "https://Tangem.OneLink.me/AbCd?deep_link_value=tpay_mobileonboard&deep_link_sub3=AbC-123&uid=AbC-123")!
    }

    enum Push {
        static func paymentWithLink(_ link: String) -> [String: String] {
            [
                "type": "card_ready",
                "customer_wallet_id": "8CD315E42BA5BD6AB6045C254A5F41BA9969E17F882A2CF7602544B870DF7D7B",
                "customer_id": "32080398-6b36-4cd5-af29-bfe18cfa30d5",
                "link": link,
            ]
        }
    }

    func makeManager() -> CommonIncomingActionManager {
        CommonIncomingActionManager()
    }

    func withRepository(_ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousBindingService = InjectedValues[\.marketingActivityBindingService]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])
            InjectedValues[\.marketingActivityBindingService] = bindingService

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.marketingActivityBindingService] = previousBindingService
            }

            await body()
        }
    }
}
