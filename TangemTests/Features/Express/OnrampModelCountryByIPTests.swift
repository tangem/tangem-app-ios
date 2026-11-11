//
//  OnrampModelCountryByIPTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("OnrampModel with the country detected by IP", .timeLimit(.minutes(1)))
struct OnrampModelCountryByIPTests {
    @Test("An IP country without onramp restricts the region and keeps loading offers instead of showing the notice")
    func unavailableIPCountryRestrictsRegion() async {
        let (sut, router, _) = makeSUT(ipCountry: .unsupported, listedCountries: [.unsupported, .supported])

        let restricted = await sut.restrictedRegionPublisher.values.first { $0 != nil }
        _ = await sut.onrampProvidersPublisher.values.first { $0 != nil }
        let unsupported = await sut.unsupportedCountryPublisher.values.first { _ in true }

        #expect(restricted == .unsupported)
        #expect(unsupported == .some(nil))
        #expect(router.bottomSheetCount == 0)
    }

    @Test("An IP country without onramp that the countries list doesn't know still shows the not-supported notice")
    func unlistedUnavailableIPCountryShowsNotice() async {
        let (sut, _, _) = makeSUT(ipCountry: .unsupported, listedCountries: [.supported])

        let unsupported = await sut.unsupportedCountryPublisher.values.first { $0 != nil }

        #expect(unsupported == .unsupported)
    }

    @Test("A supported IP country leaves the region unrestricted")
    func availableIPCountryIsNotRestricted() async {
        let (sut, _, _) = makeSUT(ipCountry: .supported, listedCountries: [.supported])

        _ = await sut.onrampProvidersPublisher.values.first { $0 != nil }
        let restricted = await sut.restrictedRegionPublisher.values.first { _ in true }

        #expect(restricted == .some(nil))
    }

    @Test("Picking another country by hand keeps the region restriction")
    func manualPickKeepsRestriction() async {
        let (sut, _, repository) = makeSUT(ipCountry: .unsupported, listedCountries: [.unsupported, .otherUnsupported])
        await waitForCountryByIP(in: sut)

        repository.selectCountry(.otherUnsupported)

        let unsupported = await sut.unsupportedCountryPublisher.values.first { $0 != nil }
        let restricted = await sut.restrictedRegionPublisher.values.first { _ in true }
        #expect(unsupported == .otherUnsupported)
        #expect(restricted == .unsupported)
    }

    @Test("An unsupported country picked by hand shows the not-supported notice")
    func manuallyPickedUnsupportedCountryShowsNotice() async {
        let (sut, router, repository) = makeSUT(ipCountry: .supported, listedCountries: [.supported, .unsupported])
        await waitForCountryByIP(in: sut)

        repository.selectCountry(.unsupported)

        let unsupported = await sut.unsupportedCountryPublisher.values.first { $0 != nil }
        #expect(unsupported == .unsupported)
        #expect(router.bottomSheetCount == 0)
    }

    @Test("Picking a supported country clears the not-supported notice")
    func pickingSupportedCountryClearsNotice() async {
        let (sut, _, repository) = makeSUT(ipCountry: .supported, listedCountries: [.supported, .unsupported])
        await waitForCountryByIP(in: sut)
        repository.selectCountry(.unsupported)
        _ = await sut.unsupportedCountryPublisher.values.first { $0 != nil }

        repository.selectCountry(.supported)

        let cleared = await sut.unsupportedCountryPublisher.values.first { $0 == nil }
        #expect(cleared == .some(nil))
    }

    @Test("A failed countries request after a country change replaces the not-supported notice with the error")
    func failedCountriesRequestClearsNotice() async {
        let dataRepository = OnrampDataRepositoryStub(countries: [.supported, .unsupported])
        let (sut, _, repository) = makeSUT(ipCountry: .supported, dataRepository: dataRepository)
        await waitForCountryByIP(in: sut)
        repository.selectCountry(.unsupported)
        _ = await sut.unsupportedCountryPublisher.values.first { $0 != nil }

        await dataRepository.failCountries()
        repository.selectCountry(.supported)

        let cleared = await sut.unsupportedCountryPublisher.values.first { $0 == nil }
        #expect(cleared == .some(nil))
    }

    @Test("A quick top-up chip's currency becomes the purchase currency instead of the country's default")
    func chipCurrencyWins() async {
        let dataRepository = OnrampDataRepositoryStub(countries: [.supported], currencies: [.usd])
        let (sut, _, repository) = makeSUT(ipCountry: .supported, dataRepository: dataRepository, fiatCurrencyCode: "USD")

        let currency = await sut.fiatCurrencyPublisher.values.first { $0 != nil }

        #expect(currency == .usd)
        #expect(repository.preferenceCountry == .supported)
    }

    @Test("A chip whose currency can't be found opens the purchase without its amount")
    func unresolvedChipCurrencyDropsAmount() async {
        let dataRepository = OnrampDataRepositoryStub(countries: [.supported], currencies: [])
        let (sut, _, _) = makeSUT(ipCountry: .supported, dataRepository: dataRepository, fiatCurrencyCode: "USD", amount: 50)

        let currency = await sut.fiatCurrencyPublisher.values.first { $0 != nil }

        #expect(currency == OnrampCountry.supported.currency)
        #expect(sut.amount == nil)
    }

    @Test("A hand-picked country after a failed IP check repeats the check instead of lifting the restriction")
    func failedIPCheckIsRepeatedForHandPickedCountry() async {
        let manager = OnrampManagerStub(ipCountry: nil)
        let (sut, _, repository) = makeSUT(
            manager: manager,
            dataRepository: OnrampDataRepositoryStub(countries: [.unsupported, .supported])
        )
        _ = await sut.errorPublisher.values.first { $0 != nil }

        await manager.setIPCountry(.unsupported)
        repository.selectCountry(.supported)

        let restricted = await sut.restrictedRegionPublisher.values.first { $0 != nil }
        #expect(restricted == .unsupported)
    }

    @Test("The IP country matches its countries-list entry by code even when the names differ")
    func ipCountryMatchesListedCountryByCode() async {
        let (sut, _, _) = makeSUT(ipCountry: .unsupported, listedCountries: [.unsupportedListedUnderAnotherName, .supported])

        _ = await sut.onrampProvidersPublisher.values.first { $0 != nil }
        let restricted = await sut.restrictedRegionPublisher.values.first { $0 != nil }
        let unsupported = await sut.unsupportedCountryPublisher.values.first { _ in true }

        #expect(restricted == .unsupported)
        #expect(unsupported == .some(nil))
    }

    @Test("An IP country missing from the countries list is treated as not supported")
    func unlistedIPCountryShowsNotice() async {
        let (sut, router, _) = makeSUT(ipCountry: .supported, listedCountries: [])

        let unsupported = await sut.unsupportedCountryPublisher.values.first { $0 != nil }

        #expect(unsupported == .supported)
        #expect(router.bottomSheetCount == 0)
    }
}

// MARK: - Helpers

private extension OnrampModelCountryByIPTests {
    func waitForCountryByIP(in sut: OnrampModel) async {
        _ = await sut.onrampProvidersPublisher.values.first { $0 != nil }
    }

    func makeSUT(
        ipCountry: OnrampCountry,
        listedCountries: [OnrampCountry]
    ) -> (sut: OnrampModel, router: OnrampModelRoutableSpy, repository: OnrampRepository) {
        makeSUT(ipCountry: ipCountry, dataRepository: OnrampDataRepositoryStub(countries: listedCountries))
    }

    func makeSUT(
        ipCountry: OnrampCountry,
        dataRepository: OnrampDataRepositoryStub,
        fiatCurrencyCode: String? = nil,
        amount: Decimal? = nil
    ) -> (sut: OnrampModel, router: OnrampModelRoutableSpy, repository: OnrampRepository) {
        makeSUT(
            manager: OnrampManagerStub(ipCountry: ipCountry),
            dataRepository: dataRepository,
            fiatCurrencyCode: fiatCurrencyCode,
            amount: amount
        )
    }

    func makeSUT(
        manager: OnrampManagerStub,
        dataRepository: OnrampDataRepositoryStub,
        fiatCurrencyCode: String? = nil,
        amount: Decimal? = nil
    ) -> (sut: OnrampModel, router: OnrampModelRoutableSpy, repository: OnrampRepository) {
        let repository = CountryByIPOnrampRepository(userCurrencyStore: OnrampUserCurrencyStore(storage: OnrampStorageStub()))
        let router = OnrampModelRoutableSpy()

        let sut = OnrampModel(
            userWalletId: "test-wallet",
            tokenItem: .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)),
            defaultAddressString: "0xtest",
            onrampManager: manager,
            onrampDataRepository: dataRepository,
            onrampRepository: repository,
            analyticsLogger: AnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            redirectSettingsBuilder: OnrampRedirectSettingsBuilder(),
            transactionHistoryEnricherFactory: { nil },
            isCountryByIPEnabled: true,
            predefinedValues: .init(amount: amount, fiatCurrencyCode: fiatCurrencyCode)
        )
        sut.router = router

        return (sut, router, repository)
    }
}

private extension OnrampFiatCurrency {
    static let usd = OnrampFiatCurrency(identity: .init(name: "US Dollar", code: "USD", image: nil), precision: 2)
}

private extension OnrampCountry {
    static let unsupported = OnrampCountry(
        identity: .init(name: "Restricted", code: "XX", image: nil),
        currency: OnrampFiatCurrency(identity: .init(name: "US Dollar", code: "USD", image: nil), precision: 2),
        onrampAvailable: false
    )

    static let unsupportedListedUnderAnotherName = OnrampCountry(
        identity: .init(name: "Restricted region", code: "XX", image: nil),
        currency: OnrampFiatCurrency(identity: .init(name: "US Dollar", code: "USD", image: nil), precision: 2),
        onrampAvailable: false
    )

    static let otherUnsupported = OnrampCountry(
        identity: .init(name: "Also restricted", code: "YY", image: nil),
        currency: OnrampFiatCurrency(identity: .init(name: "US Dollar", code: "USD", image: nil), precision: 2),
        onrampAvailable: false
    )

    static let supported = OnrampCountry(
        identity: .init(name: "Spain", code: "ES", image: nil),
        currency: OnrampFiatCurrency(identity: .init(name: "Euro", code: "EUR", image: nil), precision: 2),
        onrampAvailable: true
    )
}

// MARK: - Stubs

private final class OnrampModelRoutableSpy: OnrampModelRoutable {
    private let bottomSheetCalls = OSAllocatedUnfairLock(initialState: 0)

    var bottomSheetCount: Int { bottomSheetCalls.withLock { $0 } }

    func openOnrampCountryBottomSheet(country: OnrampCountry) {
        bottomSheetCalls.withLock { $0 += 1 }
    }

    func openOnrampCountrySelectorView() {}
    func openOnrampRedirecting() {}
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {}
    func openFinishStep() {}
    func openOnrampKYCVerification(provider: OnrampProvider, onProceedToWidget: @escaping () -> Void) {}
}

private final class OnrampStorageStub: OnrampStorage {
    private let stored = OSAllocatedUnfairLock<OnrampUserPreference?>(initialState: nil)

    func save(preference: OnrampUserPreference) {
        stored.withLock { $0 = preference }
    }

    func preference() -> OnrampUserPreference? {
        stored.withLock { $0 }
    }
}

private struct AnalyticsLoggerStub: OnrampManagementModelAnalyticsLogger {
    func logOnrampSelectedProvider(provider: OnrampProvider) {}
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String) {}
    func logOnrampNoticeBuyNotSupported() {}
}
