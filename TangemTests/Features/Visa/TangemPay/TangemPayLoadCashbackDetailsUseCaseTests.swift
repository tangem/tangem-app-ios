//
//  TangemPayLoadCashbackDetailsUseCaseTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPay
@testable import Tangem

@Suite("TangemPayCashbackDetails loaded by the use case")
struct TangemPayLoadCashbackDetailsUseCaseTests {
    @Test("every requested month is returned and totalled")
    func requestedMonths_areReturnedInOrderAndTotalled() async throws {
        let provider = makeProvider(
            history: historyResponse(months: [
                (2026, 4, "38.52"),
                (2026, 6, "32.15"),
                (2026, 2, "12.02"),
                (2026, 5, "26.10"),
                (2026, 3, "44.22"),
            ])
        )
        let requestedMonths = 5

        let sut = makeUseCase(provider: provider)
        let details = try await sut.loadCashbackDetails(months: requestedMonths)

        #expect(provider.requestedMonths == [requestedMonths])
        #expect(details.history.map(\.month) == [2, 3, 4, 5, 6])
        #expect(details.totalEarned == decimal("153.01"))
    }

    @Test("months missing from the response are filled with zeros")
    func missingMonths_areFilledWithZeros() async throws {
        let provider = makeProvider(
            history: historyResponse(months: [
                (2026, 3, "44.22"),
                (2026, 6, "32.15"),
            ])
        )
        let requestedMonths = 5

        let sut = makeUseCase(provider: provider)
        let details = try await sut.loadCashbackDetails(months: requestedMonths)

        #expect(details.history.map(\.amount) == [.zero, decimal("44.22"), .zero, .zero, decimal("32.15")])
        #expect(details.totalEarned == decimal("76.37"))
    }

    @Test("an empty response yields a zeroed window")
    func emptyResponse_yieldsZeroedWindow() async throws {
        let provider = makeProvider(history: historyResponse(months: []))

        let sut = makeUseCase(provider: provider)
        let details = try await sut.loadCashbackDetails()

        #expect(details.history.count == 5)
        #expect(details.history.allSatisfy { $0.amount == .zero })
        #expect(details.totalEarned == .zero)
    }

    @Test("a failing request fails the use case")
    func failingRequest_failsTheUseCase() async {
        let provider = StubTangemPayCashbackDataProvider(
            history: .success(historyResponse(months: [])),
            promotions: .failure(.unauthorized),
            accrualsDocs: .success(emptyResponse())
        )

        let sut = makeUseCase(provider: provider)

        await #expect(throws: TangemPayAPIServiceError.self) {
            try await sut.loadCashbackDetails()
        }
    }
}

private extension TangemPayLoadCashbackDetailsUseCaseTests {
    func makeUseCase(provider: StubTangemPayCashbackDataProvider) -> TangemPayLoadCashbackDetailsUseCase {
        TangemPayLoadCashbackDetailsUseCase(
            provider: provider,
            referenceDate: utcDate(year: 2026, month: 6, day: 15)
        )
    }

    func makeProvider(history: TangemPayCashbackHistoryResponse) -> StubTangemPayCashbackDataProvider {
        StubTangemPayCashbackDataProvider(
            history: .success(history),
            promotions: .success(emptyResponse()),
            accrualsDocs: .success(emptyResponse())
        )
    }

    func historyResponse(months: [(year: Int, month: Int, amount: String)]) -> TangemPayCashbackHistoryResponse {
        let items = months
            .map { #"{ "year": \#($0.year), "month": \#($0.month), "confirmed_amount": "\#($0.amount)" }"# }
            .joined(separator: ", ")

        return decode(#"{ "items": [\#(items)] }"#)
    }

    func emptyResponse<T: Decodable>() -> T {
        decode("{}")
    }

    func decode<T: Decodable>(_ json: String) -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let decoded = try? decoder.decode(T.self, from: Data(json.utf8)) else {
            preconditionFailure("Failed to decode \(T.self) from: \(json)")
        }

        return decoded
    }

    func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: .posixEnUS) ?? .zero
    }

    func utcDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = Calendar(identifier: .gregorian).date(from: components) else {
            preconditionFailure("Failed to build UTC date from components: \(components)")
        }

        return date
    }
}
