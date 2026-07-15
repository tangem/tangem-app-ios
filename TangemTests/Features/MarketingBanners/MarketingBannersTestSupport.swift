//
//  MarketingBannersTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

/// Use this tag for all marketing-banners suites: @Suite(.tags(.marketingBanners))
extension Tag {
    @Tag static var marketingBanners: Self
}

enum MarketingCampaignsFixtures {
    static func makeCampaign(
        id: Int = 1,
        type: String = "swap",
        priority: Int = 1,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil,
        providerIds: [String]? = nil,
        tokens: [MarketingCampaignsDTO.Campaign.Token]? = nil,
        uiType: MarketingCampaignsDTO.Banner.UIType = .standalone,
        text: String? = "Discover Bitcoin",
        icon: URL? = nil,
        bgColor: String? = nil,
        deeplink: URL? = nil,
        dismissible: Bool = false
    ) -> MarketingCampaignsDTO.Campaign {
        MarketingCampaignsDTO.Campaign(
            id: id,
            type: type,
            priority: priority,
            minAmount: minAmount,
            maxAmount: maxAmount,
            providerIds: providerIds,
            tokens: tokens,
            banner: MarketingCampaignsDTO.Banner(
                uiType: uiType,
                text: text,
                icon: icon,
                bgColor: bgColor,
                deeplink: deeplink,
                dismissible: dismissible
            )
        )
    }

    static func makeToken(
        networkId: String? = nil,
        contractAddress: String? = nil,
        id: String? = nil
    ) -> MarketingCampaignsDTO.Campaign.Token {
        MarketingCampaignsDTO.Campaign.Token(networkId: networkId, contractAddress: contractAddress, id: id)
    }
}

/// Records marketing-campaigns requests reaching the API and answers with canned campaigns (or an error).
final class MarketingCampaignsApiSpy {
    let fake = FakeTangemApiService()

    private let state = OSAllocatedUnfairLock(initialState: [MarketingCampaignsDTO.Request]())

    init(campaigns: [MarketingCampaignsDTO.Campaign], error: Error? = nil) {
        fake.loadMarketingCampaignsHandler = { [state] request in
            state.withLock { $0.append(request) }

            if let error {
                throw error
            }

            return MarketingCampaignsDTO.Response(campaigns: campaigns)
        }
    }

    var recordedRequests: [MarketingCampaignsDTO.Request] {
        state.withLock { $0 }
    }

    var callCount: Int {
        state.withLock { $0.count }
    }
}

/// Accumulates every emission of a publisher for later inspection; combine with `waitUntilConditionMet`.
final class PublisherRecorder<Output> {
    private let state = OSAllocatedUnfairLock(initialState: [Output]())
    private var cancellable: AnyCancellable?

    var values: [Output] { state.withLock { $0 } }

    init(_ publisher: AnyPublisher<Output, Never>) {
        cancellable = publisher.sink { [state] value in
            state.withLock { $0.append(value) }
        }
    }
}

/// Bounded poll for asynchronous side effects that have no awaitable handle (fire-and-forget tasks,
/// barrier-queue disk writes). Returns the final condition state, never hangs past the timeout.
func waitUntilConditionMet(
    timeout: TimeInterval = 2.0,
    condition: @escaping () -> Bool
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if condition() {
            return true
        }

        try? await Task.sleep(nanoseconds: 25_000_000)
    }

    return condition()
}

/// Waits for an emission satisfying `condition`, re-subscribing between bounded attempts.
/// `Publishers.AsyncMap` can lose an emission when its transform task finishes before `flatMap`
/// subscribes to the inner subject, so a single subscription may legitimately never fire.
/// Returns the emissions of the successful attempt, or nil when the overall timeout expires.
func awaitEmissions<Output>(
    timeout: TimeInterval = 2.0,
    attemptTimeout: TimeInterval = 0.5,
    of makePublisher: () -> AnyPublisher<Output, Never>,
    where condition: @escaping ([Output]) -> Bool
) async -> [Output]? {
    let deadline = Date().addingTimeInterval(timeout)

    repeat {
        let recorder = PublisherRecorder(makePublisher())
        let attemptDeadline = min(deadline, Date().addingTimeInterval(attemptTimeout))

        while Date() < attemptDeadline {
            if condition(recorder.values) {
                return recorder.values
            }

            try? await Task.sleep(nanoseconds: 25_000_000)
        }

        if condition(recorder.values) {
            return recorder.values
        }
    } while Date() < deadline

    return nil
}
