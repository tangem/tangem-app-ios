//
//  OnrampCountryByIPServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("Shared country-by-ip lookup")
struct OnrampCountryByIPServiceTests {
    @Test("A second request within the lifetime reuses the first answer")
    func answerIsReusedWithinLifetime() async throws {
        let (sut, clock, _, api) = makeSUT()

        _ = try await sut.country(fetch: api.fetch)
        clock.advance(by: 59)
        let country = try await sut.country(fetch: api.fetch)

        #expect(country == .spainByIP)
        #expect(api.requestCount == 1)
    }

    @Test("A request after the lifetime asks again")
    func answerExpires() async throws {
        let (sut, clock, _, api) = makeSUT()

        _ = try await sut.country(fetch: api.fetch)
        clock.advance(by: 60)
        _ = try await sut.country(fetch: api.fetch)

        #expect(api.requestCount == 2)
    }

    @Test("A request after the system clock was set back asks again")
    func answerExpiresWhenClockGoesBack() async throws {
        let (sut, clock, _, api) = makeSUT()

        _ = try await sut.country(fetch: api.fetch)
        clock.advance(by: -3600)
        _ = try await sut.country(fetch: api.fetch)

        #expect(api.requestCount == 2)
    }

    @Test("A request after the network changed asks again")
    func answerExpiresWhenNetworkChanges() async throws {
        let (sut, _, network, api) = makeSUT()

        _ = try await sut.country(fetch: api.fetch)
        network.change()
        _ = try await sut.country(fetch: api.fetch)
        _ = try await sut.country(fetch: api.fetch)

        #expect(api.requestCount == 2)
    }

    @Test("A failed request is not remembered")
    func failureIsNotCached() async throws {
        let (sut, _, _, api) = makeSUT()
        api.failNext()

        await #expect(throws: TestError.self) { try await sut.country(fetch: api.fetch) }
        let country = try await sut.country(fetch: api.fetch)

        #expect(country == .spainByIP)
        #expect(api.requestCount == 2)
    }

    @Test("Screens asking while a request is running wait for it instead of asking again")
    func concurrentRequestsShareOneFetch() async throws {
        let entries = AsyncStream<Void>.makeStream()
        let sut = CommonOnrampCountryByIPService(lifetime: 0, now: {
            entries.continuation.yield()
            return Date(timeIntervalSince1970: 0)
        }, networkPathVersion: { 0 })
        let api = GatedCountryByIPAPIStub()

        async let first = sut.country(fetch: api.fetch)
        async let second = sut.country(fetch: api.fetch)
        async let third = sut.country(fetch: api.fetch)

        var iterator = entries.stream.makeAsyncIterator()
        for _ in 0 ..< 3 {
            await iterator.next()
        }
        api.release()

        let countries = try await [first, second, third]

        #expect(countries == [.spainByIP, .spainByIP, .spainByIP])
        #expect(api.requestCount == 1)
    }

    @Test("A request started before the network changed is neither joined nor remembered")
    func requestFromPreviousNetworkIsNotShared() async throws {
        let network = ManualNetworkPath()
        let sut = CommonOnrampCountryByIPService(
            lifetime: 60,
            now: { Date(timeIntervalSince1970: 0) },
            networkPathVersion: { network.version }
        )
        let api = GatedCountryByIPAPIStub()
        var requests = api.requests.makeAsyncIterator()

        async let beforeChange = sut.country(fetch: api.fetch)
        await requests.next()
        network.change()
        async let afterChange = sut.country(fetch: api.fetch)
        await requests.next()
        api.release()

        _ = try await [beforeChange, afterChange]
        _ = try await sut.country(fetch: api.fetch)

        #expect(api.requestCount == 2)
    }
}

// MARK: - Helpers

private extension OnrampCountryByIPServiceTests {
    func makeSUT() -> (CommonOnrampCountryByIPService, ManualDate, ManualNetworkPath, CountryByIPAPIStub) {
        let clock = ManualDate()
        let network = ManualNetworkPath()
        let sut = CommonOnrampCountryByIPService(
            lifetime: 60,
            now: { clock.now },
            networkPathVersion: { network.version }
        )
        return (sut, clock, network, CountryByIPAPIStub())
    }
}

private struct TestError: Error {}

private final class ManualDate: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 0))

    var now: Date { state.withLock { $0 } }

    func advance(by seconds: TimeInterval) {
        state.withLock { $0 += seconds }
    }
}

private final class ManualNetworkPath: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var version: Int { state.withLock { $0 } }

    func change() {
        state.withLock { $0 += 1 }
    }
}

private final class CountryByIPAPIStub: Sendable {
    private struct State {
        var requestCount = 0
        var shouldFail = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestCount: Int { state.withLock { $0.requestCount } }

    func failNext() {
        state.withLock { $0.shouldFail = true }
    }

    func fetch() async throws -> OnrampCountry {
        let shouldFail = state.withLock { state in
            state.requestCount += 1
            defer { state.shouldFail = false }
            return state.shouldFail
        }

        if shouldFail {
            throw TestError()
        }

        return .spainByIP
    }
}

private final class GatedCountryByIPAPIStub: Sendable {
    private struct State {
        var requestCount = 0
        var isReleased = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let requestsStream = AsyncStream<Void>.makeStream()

    var requestCount: Int { state.withLock { $0.requestCount } }

    var requests: AsyncStream<Void> { requestsStream.stream }

    func release() {
        let waiters = state.withLock { state in
            state.isReleased = true
            defer { state.waiters = [] }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    func fetch() async throws -> OnrampCountry {
        await withCheckedContinuation { continuation in
            let isReleased = state.withLock { state in
                state.requestCount += 1

                if !state.isReleased {
                    state.waiters.append(continuation)
                }

                return state.isReleased
            }

            requestsStream.continuation.yield()

            if isReleased {
                continuation.resume()
            }
        }

        return .spainByIP
    }
}

private extension OnrampCountry {
    static let spainByIP = OnrampCountry(
        identity: .init(name: "Spain", code: "ES", image: nil),
        currency: OnrampFiatCurrency(identity: .init(name: "Euro", code: "EUR", image: nil), precision: 2),
        onrampAvailable: true
    )
}
