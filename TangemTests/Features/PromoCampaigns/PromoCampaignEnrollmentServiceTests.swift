//
//  PromoCampaignEnrollmentServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
import enum Moya.MoyaError
import class Moya.Response
import enum Alamofire.AFError
@testable import Tangem

@Suite("PromoCampaignEnrollmentService")
struct PromoCampaignEnrollmentServiceTests {
    private let walletA = UserWalletId(value: Data([0xAA]))
    private let walletB = UserWalletId(value: Data([0xBB]))
    private let walletC = UserWalletId(value: Data([0xCC]))
    private let userAddress = "0xUserAddress"

    // MARK: - Request

    @Test("A strict campaign sends only the wallet the sheet was opened from, as the main one")
    func strictCampaignSendsInitiatingWalletOnly() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletB, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA), cardWallet(walletB)], api: api)

        _ = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletB, payout: nil)

        #expect(api.campaignIds == [42])
        #expect(api.requests.first?.enrollments == [
            PromoCampaignEnrollmentDTO.Enrollment(
                walletId: walletB.stringValue,
                walletType: .card,
                batchId: "AF04",
                userAddress: nil,
                tokenAddress: nil,
                networkId: nil,
                tokenId: nil,
                main: true
            ),
        ])
    }

    @Test("A linked-wallet campaign sends every wallet with one payout address, the initiating one first and main")
    func linkedWalletCampaignSendsEveryWallet() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletB, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA), cardWallet(walletB), mobileWallet(walletC)], api: api)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true, matchMode: .linkedWallet)

        _ = await sut.enroll(in: campaign, from: walletB, payout: PromoCampaignPayoutSelection(tokenItem: CampaignsFixtures.usdcOnEthereum, address: userAddress))

        let enrollments = try #require(api.requests.first).enrollments
        #expect(enrollments.map(\.walletId) == [walletB, walletA, walletC].map(\.stringValue))
        #expect(enrollments.map(\.main) == [true, false, false])
        #expect(Set(enrollments.map(\.userAddress)) == [userAddress])
    }

    @Test("A campaign with a payout sends the chosen token as the campaign lists it")
    func payoutCampaignSendsChosenToken() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true)

        _ = await sut.enroll(in: campaign, from: walletA, payout: PromoCampaignPayoutSelection(tokenItem: CampaignsFixtures.usdcOnEthereum, address: userAddress))

        let enrollment = try #require(api.requests.first?.enrollments.first)
        #expect(enrollment.userAddress == userAddress)
        #expect(enrollment.tokenAddress == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
        #expect(enrollment.networkId == "ethereum")
        #expect(enrollment.tokenId == "usd-coin")
    }

    @Test("A campaign with a payout is not requested without a payout token")
    func payoutCampaignWithoutTokenIsNotRequested() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true), from: walletA, payout: nil)

        #expect(outcome == .failed)
        #expect(api.requests.isEmpty)
    }

    @Test("A campaign with a payout is not requested with a token it doesn't list")
    func payoutCampaignWithUnlistedTokenIsNotRequested() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)
        let ethereumCoin: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

        let outcome = await sut.enroll(
            in: PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true),
            from: walletA,
            payout: PromoCampaignPayoutSelection(tokenItem: ethereumCoin, address: userAddress)
        )

        #expect(outcome == .failed)
        #expect(api.requests.isEmpty)
    }

    @Test("A wallet the app does not know is not requested")
    func unknownWalletIsNotRequested() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletB, payout: nil)

        #expect(outcome == .failed)
        #expect(api.requests.isEmpty)
    }

    @Test("The body leaves the payout fields and the batch out when there are none")
    func bodyOmitsAbsentFields() throws {
        let enrollment = PromoCampaignEnrollmentDTO.Enrollment(wallet: mobileWallet(walletA), userAddress: nil, payoutToken: nil, isMain: true)

        let item = try encodeFirstEnrollment(PromoCampaignEnrollmentDTO.Request(enrollments: [enrollment]))

        #expect(Set(item.keys) == ["walletId", "walletType", "main"])
        #expect(item["walletType"] as? String == "mobile")
        #expect(item["main"] as? Bool == true)
    }

    @Test("The body carries every payout field and the batch when they are known")
    func bodyCarriesPayoutFields() throws {
        let enrollment = PromoCampaignEnrollmentDTO.Enrollment(
            wallet: cardWallet(walletA),
            userAddress: userAddress,
            payoutToken: PromotionCampaignsFixtures.makeEligibleToken(),
            isMain: false
        )

        let item = try encodeFirstEnrollment(PromoCampaignEnrollmentDTO.Request(enrollments: [enrollment]))

        #expect(Set(item.keys) == ["walletId", "walletType", "batchId", "userAddress", "tokenAddress", "networkId", "tokenId", "main"])
        #expect(item["batchId"] as? String == "AF04")
        #expect(item["main"] as? Bool == false)
    }

    // MARK: - Outcome

    @Test("Wallets enrolled now come back with their payout and the campaign's token")
    func enrolledWalletsComeBackWithPayout() async throws {
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")], withPayout: true))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true)

        let outcome = await sut.enroll(in: campaign, from: walletA, payout: PromoCampaignPayoutSelection(tokenItem: CampaignsFixtures.usdcOnEthereum, address: userAddress))

        let payout = PromoCampaignPayout(
            userAddress: userAddress,
            tokenAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            networkId: "ethereum",
            token: PromotionCampaignsFixtures.makeEligibleToken()
        )
        #expect(outcome == .enrolled([PromoCampaignEnrollment(userWalletId: walletA, payout: payout)]))
    }

    @Test("Several wallets enrolled now make one full success")
    func severalEnrolledWallets() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "enrolled"), (walletB, "enrolled")])

        #expect(outcome == .enrolled([enrollment(walletA), enrollment(walletB)]))
    }

    @Test("Wallets enrolled before make the already-enrolled outcome")
    func alreadyEnrolledWallets() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "already_enrolled"), (walletB, "already_enrolled")])

        #expect(outcome == .alreadyEnrolled([enrollment(walletA), enrollment(walletB)]))
    }

    @Test("A mix of new and earlier enrollments is a partial success")
    func mixedEnrollments() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "enrolled"), (walletB, "already_enrolled")])

        #expect(outcome == .partiallyEnrolled(enrolled: [enrollment(walletA)], alreadyEnrolled: [enrollment(walletB)]))
    }

    @Test("An ineligible wallet makes the campaign unavailable")
    func ineligibleWallet() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "ineligible")])

        #expect(outcome == .unavailable)
    }

    @Test("An ineligible main wallet makes the campaign unavailable whatever the other wallets got", arguments: ["enrolled", "already_enrolled"])
    func ineligibleMainWallet(otherStatus: String) async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "ineligible"), (walletB, otherStatus)])

        #expect(outcome == .unavailable)
    }

    @Test("An ineligible linked wallet doesn't spoil the main wallet's success")
    func ineligibleLinkedWallet() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "enrolled"), (walletB, "ineligible")])

        #expect(outcome == .enrolled([enrollment(walletA)]))
    }

    @Test("An answer about none of the sent wallets is an error")
    func answerWithoutKnownWallets() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletC, "enrolled")])

        #expect(outcome == .failed)
    }

    @Test("A status the app does not know is skipped without losing the others")
    func unknownStatusIsSkipped() async throws {
        let outcome = try await enrollLinkedWallets(answering: [(walletA, "pending"), (walletB, "enrolled")])

        #expect(outcome == .enrolled([enrollment(walletB)]))
    }

    @Test("Any other rejection of the request is an error", arguments: [400, 401, 500])
    func otherRejectionIsAnError(statusCode: Int) async {
        let api = EnrollmentApiStub(error: Self.statusCodeError(statusCode))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletA, payout: nil)

        #expect(outcome == .failed)
    }

    @Test("A connection failure is an error")
    func connectionFailure() async {
        let api = EnrollmentApiStub(error: MoyaError.underlying(AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet)), nil))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletA, payout: nil)

        #expect(outcome == .failed)
    }

    // MARK: - Campaigns cache

    @Test("A campaign gone for good is unavailable and removed from the cache")
    func goneCampaignIsRemoved() async {
        let repository = CampaignsRepositorySpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: Self.statusCodeError(404)), repository: repository)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletA, payout: nil)

        #expect(outcome == .unavailable)
        #expect(repository.removedCampaignIds == [42])
        #expect(repository.reloadedWalletIds.isEmpty)
    }

    @Test("A campaign paused for now is temporarily unavailable and stays in the cache")
    func pausedCampaignIsKept() async {
        let repository = CampaignsRepositorySpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: Self.statusCodeError(409)), repository: repository)

        let outcome = await sut.enroll(in: PromoCampaignFixtures.makeCampaign(id: 42), from: walletA, payout: nil)

        #expect(outcome == .temporarilyUnavailable)
        #expect(repository.removedCampaignIds.isEmpty)
    }

    @Test("Every wallet that ended up enrolled has its campaigns reloaded")
    func enrolledWalletsAreReloaded() async throws {
        let repository = CampaignsRepositorySpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "enrolled"), (walletB, "already_enrolled")], repository: repository)

        #expect(repository.reloadedWalletIds == [[walletA, walletB]])
    }

    @Test("Ineligible wallets have their campaigns reloaded so their banners can go")
    func ineligibleWalletsAreReloaded() async throws {
        let repository = CampaignsRepositorySpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "ineligible"), (walletB, "ineligible")], repository: repository)

        #expect(repository.reloadedWalletIds == [[walletA, walletB]])
    }

    @Test("Every wallet in a mixed answer has its campaigns reloaded")
    func mixedAnswerReloadsEveryWallet() async throws {
        let repository = CampaignsRepositorySpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "ineligible"), (walletB, "enrolled")], repository: repository)

        #expect(repository.reloadedWalletIds == [[walletA, walletB]])
    }

    @Test("Nothing is reloaded when the answer is about none of the sent wallets")
    func nothingIsReloadedWithoutKnownWallets() async throws {
        let repository = CampaignsRepositorySpy()

        _ = try await enrollLinkedWallets(answering: [(walletC, "enrolled")], repository: repository)

        #expect(repository.reloadedWalletIds.isEmpty)
    }

    @Test("A result whose payout can't be read still counts, without the payout")
    func unreadablePayoutKeepsTheResult() throws {
        let json = #"{ "results": [{ "walletId": "aa", "status": "enrolled", "payout": { "userAddress": null } }] }"#

        let response = try Self.decoder.decode(PromoCampaignEnrollmentDTO.Response.self, from: Data(json.utf8))

        #expect(response.results.map(\.walletId) == ["aa"])
        #expect(response.results.first?.payout == nil)
    }

    // MARK: - Analytics

    @Test("The enroll tap is reported with the chosen payout token and every wallet sent")
    func enrollTapIsReported() async throws {
        let analytics = AnalyticsLoggerSpy()
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA), mobileWallet(walletB)], api: api, analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true, matchMode: .linkedWallet)

        _ = await sut.enroll(in: campaign, from: walletA, payout: PromoCampaignPayoutSelection(tokenItem: CampaignsFixtures.usdcOnEthereum, address: userAddress))

        #expect(analytics.events.first == .enrollButtonClicked(campaign: campaign, payoutToken: CampaignsFixtures.usdcOnEthereum, walletsCount: 2))
    }

    @Test("Every event of a linked-wallet enrollment goes out for the wallet the sheet was opened from")
    func eventsGoOutForInitiatingWallet() async throws {
        let analytics = AnalyticsLoggerSpy()
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled"), (walletB, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA), mobileWallet(walletB)], api: api, analytics: analytics)

        _ = await sut.enroll(in: linkedCampaign, from: walletB, payout: nil)

        #expect(analytics.userWalletIds == [walletB, walletB])
    }

    @Test("A campaign without a payout reports no payout token even when one is passed")
    func campaignWithoutPayoutReportsNoToken() async throws {
        let analytics = AnalyticsLoggerSpy()
        let api = try EnrollmentApiStub(response: makeResponse([(walletA, "enrolled")]))
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: api, analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42)

        _ = await sut.enroll(in: campaign, from: walletA, payout: PromoCampaignPayoutSelection(tokenItem: CampaignsFixtures.usdcOnEthereum, address: userAddress))

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 1),
            .enrollSuccessful(campaign: campaign, payoutToken: nil, walletsEnrolled: 1, walletsTotal: 1),
        ])
    }

    @Test("A success counts the enrolled wallets against every item of the answer", arguments: [
        ([(0, "enrolled"), (1, "enrolled")], 2, 2),
        ([(0, "enrolled"), (1, "already_enrolled")], 1, 2),
        ([(0, "enrolled"), (1, "ineligible")], 1, 2),
    ])
    func successCountsEnrolledWallets(answer: [(Int, String)], walletsEnrolled: Int, walletsTotal: Int) async throws {
        let analytics = AnalyticsLoggerSpy()
        let wallets = [walletA, walletB]

        _ = try await enrollLinkedWallets(answering: answer.map { (wallets[$0.0], $0.1) }, analytics: analytics)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: linkedCampaign, payoutToken: nil, walletsCount: 2),
            .enrollSuccessful(campaign: linkedCampaign, payoutToken: nil, walletsEnrolled: walletsEnrolled, walletsTotal: walletsTotal),
        ])
    }

    @Test("Wallets that were all enrolled before report neither a success nor an error")
    func alreadyEnrolledReportsNoResult() async throws {
        let analytics = AnalyticsLoggerSpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "already_enrolled")], analytics: analytics)

        #expect(analytics.events == [.enrollButtonClicked(campaign: linkedCampaign, payoutToken: nil, walletsCount: 2)])
    }

    @Test("An answer the campaign rejects every wallet in is reported as unavailable with the answer's status code")
    func ineligibleAnswerIsReportedUnavailable() async throws {
        let analytics = AnalyticsLoggerSpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "ineligible")], analytics: analytics)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: linkedCampaign, payoutToken: nil, walletsCount: 2),
            .enrollError(campaign: linkedCampaign, reason: .unavailable, statusCode: 200),
        ])
    }

    @Test("An ineligible main wallet is reported as unavailable even when another wallet got enrolled")
    func ineligibleMainWalletIsReportedUnavailable() async throws {
        let analytics = AnalyticsLoggerSpy()

        _ = try await enrollLinkedWallets(answering: [(walletA, "ineligible"), (walletB, "enrolled")], analytics: analytics)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: linkedCampaign, payoutToken: nil, walletsCount: 2),
            .enrollError(campaign: linkedCampaign, reason: .unavailable, statusCode: 200),
        ])
    }

    @Test("An answer about none of the sent wallets is reported as a technical error")
    func unknownWalletsAnswerIsReportedTechnical() async throws {
        let analytics = AnalyticsLoggerSpy()

        _ = try await enrollLinkedWallets(answering: [(walletC, "enrolled")], analytics: analytics)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: linkedCampaign, payoutToken: nil, walletsCount: 2),
            .enrollError(campaign: linkedCampaign, reason: .technical, statusCode: 200),
        ])
    }

    @Test("A rejected request is reported with its reason and status code", arguments: [
        (404, PromoCampaignAnalyticsEvent.EnrollErrorReason.unavailable),
        (409, .notActiveYet),
        (400, .technical),
        (401, .technical),
        (500, .technical),
    ])
    func rejectedRequestIsReported(statusCode: Int, reason: PromoCampaignAnalyticsEvent.EnrollErrorReason) async {
        let analytics = AnalyticsLoggerSpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: Self.statusCodeError(statusCode)), analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42)

        _ = await sut.enroll(in: campaign, from: walletA, payout: nil)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 1),
            .enrollError(campaign: campaign, reason: reason, statusCode: statusCode),
        ])
    }

    @Test("A connection failure is reported as a technical error without a code")
    func connectionFailureIsReported() async {
        let analytics = AnalyticsLoggerSpy()
        let error = MoyaError.underlying(AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet)), nil)
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: error), analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42)

        _ = await sut.enroll(in: campaign, from: walletA, payout: nil)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 1),
            .enrollError(campaign: campaign, reason: .technical, statusCode: nil),
        ])
    }

    @Test("A cancelled request reports no result")
    func cancelledRequestReportsNoResult() async {
        let analytics = AnalyticsLoggerSpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: CancellationError()), analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42)

        _ = await sut.enroll(in: campaign, from: walletA, payout: nil)

        #expect(analytics.events == [.enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 1)])
    }

    @Test("A campaign with a payout tapped without a payout token is reported as a technical error")
    func missingPayoutTokenIsReported() async {
        let analytics = AnalyticsLoggerSpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: Self.statusCodeError(500)), analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true)

        _ = await sut.enroll(in: campaign, from: walletA, payout: nil)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 1),
            .enrollError(campaign: campaign, reason: .technical, statusCode: nil),
        ])
    }

    @Test("A wallet the app does not know is reported as a technical error after a tap with no wallets")
    func unknownInitiatingWalletIsReported() async {
        let analytics = AnalyticsLoggerSpy()
        let sut = makeSUT(wallets: [mobileWallet(walletA)], api: EnrollmentApiStub(error: Self.statusCodeError(500)), analytics: analytics)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42)

        _ = await sut.enroll(in: campaign, from: walletB, payout: nil)

        #expect(analytics.events == [
            .enrollButtonClicked(campaign: campaign, payoutToken: nil, walletsCount: 0),
            .enrollError(campaign: campaign, reason: .technical, statusCode: nil),
        ])
    }
}

// MARK: - Helpers

private extension PromoCampaignEnrollmentServiceTests {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func statusCodeError(_ statusCode: Int) -> MoyaError {
        let validationError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
        return MoyaError.underlying(validationError, Response(statusCode: statusCode, data: Data()))
    }

    var linkedCampaign: PromoCampaign {
        PromoCampaignFixtures.makeCampaign(id: 42, matchMode: .linkedWallet)
    }

    func makeSUT(
        wallets: [PromoCampaignWallet],
        api: EnrollmentApiStub,
        repository: CampaignsRepositorySpy = CampaignsRepositorySpy(),
        analytics: AnalyticsLoggerSpy = AnalyticsLoggerSpy()
    ) -> CommonPromoCampaignEnrollmentService {
        CommonPromoCampaignEnrollmentService(
            walletsProvider: EnrollmentWalletsProviderStub(wallets: wallets),
            campaignsRepository: repository,
            tangemApiService: api.service,
            analyticsLogger: analytics
        )
    }

    func enrollLinkedWallets(
        answering results: [(userWalletId: UserWalletId, status: String)],
        repository: CampaignsRepositorySpy = CampaignsRepositorySpy(),
        analytics: AnalyticsLoggerSpy = AnalyticsLoggerSpy()
    ) async throws -> PromoCampaignEnrollmentOutcome {
        let api = try EnrollmentApiStub(response: makeResponse(results))
        let sut = makeSUT(wallets: [mobileWallet(walletA), mobileWallet(walletB)], api: api, repository: repository, analytics: analytics)

        return await sut.enroll(in: linkedCampaign, from: walletA, payout: nil)
    }

    func makeResponse(
        _ results: [(userWalletId: UserWalletId, status: String)],
        withPayout: Bool = false
    ) throws -> PromoCampaignEnrollmentDTO.Response {
        let payout = withPayout
            ? #"{ "userAddress": "\#(userAddress)", "tokenAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "networkId": "ethereum" }"#
            : "null"
        let items = results.map { result in
            #"{ "walletId": "\#(result.userWalletId.stringValue)", "status": "\#(result.status)", "payout": \#(payout) }"#
        }
        let json = #"{ "id": 42, "results": [\#(items.joined(separator: ", "))] }"#

        return try Self.decoder.decode(PromoCampaignEnrollmentDTO.Response.self, from: Data(json.utf8))
    }

    func encodeFirstEnrollment(_ request: PromoCampaignEnrollmentDTO.Request) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require((json["enrollments"] as? [[String: Any]])?.first)
    }

    func enrollment(_ userWalletId: UserWalletId) -> PromoCampaignEnrollment {
        PromoCampaignEnrollment(userWalletId: userWalletId, payout: nil)
    }

    func mobileWallet(_ userWalletId: UserWalletId) -> PromoCampaignWallet {
        PromoCampaignWallet(userWalletId: userWalletId, identity: .mobile)
    }

    func cardWallet(_ userWalletId: UserWalletId) -> PromoCampaignWallet {
        PromoCampaignWallet(userWalletId: userWalletId, identity: .card(batchId: "AF04"))
    }
}

// MARK: - Stubs

private final class EnrollmentApiStub {
    let service = FakeTangemApiService()

    private let state = OSAllocatedUnfairLock(initialState: State())

    init(response: PromoCampaignEnrollmentDTO.Response) {
        service.enrollInPromoCampaignHandler = { [state] id, request in
            state.withLock { $0.record(id: id, request: request) }
            return response
        }
    }

    init(error: any Error) {
        service.enrollInPromoCampaignHandler = { [state] id, request in
            state.withLock { $0.record(id: id, request: request) }
            throw error
        }
    }

    var campaignIds: [Int] {
        state.withLock { $0.campaignIds }
    }

    var requests: [PromoCampaignEnrollmentDTO.Request] {
        state.withLock { $0.requests }
    }

    private struct State {
        var campaignIds: [Int] = []
        var requests: [PromoCampaignEnrollmentDTO.Request] = []

        mutating func record(id: Int, request: PromoCampaignEnrollmentDTO.Request) {
            campaignIds.append(id)
            requests.append(request)
        }
    }
}

private struct EnrollmentWalletsProviderStub: PromoCampaignWalletsProviding {
    let wallets: [PromoCampaignWallet]

    var walletsPublisher: AnyPublisher<[PromoCampaignWallet], Never> {
        Just(wallets).eraseToAnyPublisher()
    }
}

private final class CampaignsRepositorySpy: PromoCampaignsProviding {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var reloadedWalletIds: [[UserWalletId]] {
        state.withLock { $0.reloadedWalletIds }
    }

    var removedCampaignIds: [Int] {
        state.withLock { $0.removedCampaignIds }
    }

    func initialize() {}

    func campaignsPublisher(for userWalletId: UserWalletId) -> AnyPublisher<[PromoCampaign], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func reloadCampaigns(for userWalletIds: [UserWalletId]) {
        state.withLock { $0.reloadedWalletIds.append(userWalletIds) }
    }

    func removeCampaign(withId campaignId: Int) {
        state.withLock { $0.removedCampaignIds.append(campaignId) }
    }

    private struct State {
        var reloadedWalletIds: [[UserWalletId]] = []
        var removedCampaignIds: [Int] = []
    }
}

private final class AnalyticsLoggerSpy: PromoCampaignAnalyticsLogging {
    private let state = OSAllocatedUnfairLock(initialState: [(event: PromoCampaignAnalyticsEvent, userWalletId: UserWalletId)]())

    var events: [PromoCampaignAnalyticsEvent] {
        state.withLock { $0.map(\.event) }
    }

    var userWalletIds: [UserWalletId] {
        state.withLock { $0.map(\.userWalletId) }
    }

    func log(_ event: PromoCampaignAnalyticsEvent, userWalletId: UserWalletId) {
        state.withLock { $0.append((event, userWalletId)) }
    }
}
