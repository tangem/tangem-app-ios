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

    func makeSUT(
        wallets: [PromoCampaignWallet],
        api: EnrollmentApiStub,
        repository: CampaignsRepositorySpy = CampaignsRepositorySpy()
    ) -> CommonPromoCampaignEnrollmentService {
        CommonPromoCampaignEnrollmentService(
            walletsProvider: EnrollmentWalletsProviderStub(wallets: wallets),
            campaignsRepository: repository,
            tangemApiService: api.service
        )
    }

    func enrollLinkedWallets(
        answering results: [(userWalletId: UserWalletId, status: String)],
        repository: CampaignsRepositorySpy = CampaignsRepositorySpy()
    ) async throws -> PromoCampaignEnrollmentOutcome {
        let api = try EnrollmentApiStub(response: makeResponse(results))
        let sut = makeSUT(wallets: [mobileWallet(walletA), mobileWallet(walletB)], api: api, repository: repository)
        let campaign = PromoCampaignFixtures.makeCampaign(id: 42, matchMode: .linkedWallet)

        return await sut.enroll(in: campaign, from: walletA, payout: nil)
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
