//
//  CommonAddressBookNetworkServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemSdk
import TangemFoundation
@testable import Tangem

@Suite("CommonAddressBookNetworkService")
struct CommonAddressBookNetworkServiceTests {
    private let walletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))

    private static let nonceHex = "000102030405060708090a0b"
    private static let ciphertextHex = "deadbeef"
    private static let tagHex = "6c4b71b27958f43afc6633850369a17a"

    private let updatedAt = Date(timeIntervalSince1970: 1_750_000_000)
    private var updatedAtWire: String { AddressBookBlobCodec.dateFormatter.string(from: updatedAt) }

    // MARK: - Load: request shape

    @Test
    func loadSendsWalletIdInOriginalCaseWithoutETag() async throws {
        let api = MockTangemApiService()
        api.syncResult = .success(AddressBookDTO.Response(items: []))
        let service = CommonAddressBookNetworkService(api: api)

        _ = try await service.loadAddressBook(walletId: walletId, knownETag: nil)

        let request = try #require(api.syncRequests.first)
        let wallet = try #require(request.wallets.first)
        #expect(api.syncRequests.count == 1)
        #expect(request.wallets.count == 1)
        #expect(wallet.walletId == walletId.stringValue)
        #expect(wallet.walletId != walletId.stringValue.lowercased())
        #expect(wallet.etag == nil)
    }

    // MARK: - Load: empty items

    @Test
    func emptyItemsDistinguishNotFoundFromNotModifiedByETag() async throws {
        let api = MockTangemApiService()
        api.syncResult = .success(AddressBookDTO.Response(items: []))
        let service = CommonAddressBookNetworkService(api: api)

        let noETag = try await service.loadAddressBook(walletId: walletId, knownETag: nil)
        #expect(noETag == .notFound)

        let withETag = try await service.loadAddressBook(walletId: walletId, knownETag: "etag-123")
        #expect(withETag == .notModified)

        #expect(api.syncRequests.last?.wallets.first?.etag == "etag-123")
    }

    // MARK: - Load: fetched mapping

    @Test
    func fetchedResponseIsMappedIntoEnvelopeWithParsedUpdatedAt() async throws {
        let item = AddressBookDTO.Response.Item(
            walletId: walletId.stringValue,
            etag: "etag-remote",
            version: "1.0",
            updatedAt: updatedAtWire,
            nonce: Self.nonceHex,
            ciphertext: Self.ciphertextHex,
            authTag: Self.tagHex
        )
        let api = MockTangemApiService()
        api.syncResult = .success(AddressBookDTO.Response(items: [item]))
        let service = CommonAddressBookNetworkService(api: api)

        let result = try await service.loadAddressBook(walletId: walletId, knownETag: "prev")

        guard case .fetched(let remote) = result else {
            Issue.record("Expected .fetched, got \(result)")
            return
        }
        #expect(remote.etag == "etag-remote")
        #expect(remote.envelope.version == "1.0")
        #expect(remote.envelope.walletId == walletId)
        #expect(remote.envelope.updatedAt == updatedAt)
        #expect(remote.envelope.sealedBox == expectedSealedBox)
    }

    // MARK: - Load: error mapping

    @Test
    func mappingFailureBecomesMalformedResponse() async throws {
        let badItem = AddressBookDTO.Response.Item(
            walletId: walletId.stringValue,
            etag: "etag-remote",
            version: "1.0",
            updatedAt: updatedAtWire,
            nonce: "00",
            ciphertext: Self.ciphertextHex,
            authTag: Self.tagHex
        )
        let api = MockTangemApiService()
        api.syncResult = .success(AddressBookDTO.Response(items: [badItem]))
        let service = CommonAddressBookNetworkService(api: api)

        do {
            _ = try await service.loadAddressBook(walletId: walletId, knownETag: nil)
            Issue.record("Expected .malformedResponse to be thrown")
        } catch AddressBookNetworkServiceError.malformedResponse(let underlying) {
            guard case AddressBookNetworkMapper.MappingError.invalidLength(field: .nonce, expected: _, actual: _) = underlying else {
                Issue.record("Expected .invalidLength(.nonce), got \(underlying)")
                return
            }
        } catch {
            Issue.record("Expected .malformedResponse, got \(error)")
        }
    }

    @Test
    func arbitraryApiErrorBecomesUnderlyingError() async throws {
        let api = MockTangemApiService()
        api.syncResult = .failure(TestError.boom)
        let service = CommonAddressBookNetworkService(api: api)

        do {
            _ = try await service.loadAddressBook(walletId: walletId, knownETag: nil)
            Issue.record("Expected .underlyingError to be thrown")
        } catch AddressBookNetworkServiceError.underlyingError(let underlying) {
            #expect(underlying is TestError)
        } catch {
            Issue.record("Expected .underlyingError, got \(error)")
        }
    }

    // MARK: - Save

    @Test
    func saveSendsOriginalCaseWalletIdAndParsesSaveResult() async throws {
        let api = MockTangemApiService()
        api.updateResult = .success(AddressBookDTO.UpdateResponse(
            walletId: walletId.stringValue,
            updatedAt: updatedAtWire,
            etag: "etag-saved"
        ))
        let service = CommonAddressBookNetworkService(api: api)
        let envelope = makeEnvelope()

        let result = try await service.saveAddressBook(envelope, walletId: walletId, knownETag: "prev-etag")

        #expect(result.etag == "etag-saved")
        #expect(result.updatedAt == updatedAt)

        let call = try #require(api.updateCalls.first)
        #expect(call.walletId == walletId.stringValue)
        #expect(call.walletId != walletId.stringValue.lowercased())
        #expect(call.knownETag == "prev-etag")
        #expect(call.body.version == "1.0")
        #expect(call.body.nonce == envelope.sealedBox.nonce.hexString)
        #expect(call.body.ciphertext == envelope.sealedBox.ciphertext.hexString)
        #expect(call.body.authTag == envelope.sealedBox.tag.hexString)
    }

    @Test
    func optimisticLockingFailureBecomesInconsistentState() async throws {
        let api = MockTangemApiService()
        api.updateResult = .failure(TangemAPIError(code: .optimisticLockingFailed))
        let service = CommonAddressBookNetworkService(api: api)

        do {
            _ = try await service.saveAddressBook(makeEnvelope(), walletId: walletId, knownETag: "prev")
            Issue.record("Expected .inconsistentState to be thrown")
        } catch AddressBookNetworkServiceError.inconsistentState {
        } catch {
            Issue.record("Expected .inconsistentState, got \(error)")
        }
    }

    // MARK: - Fixtures

    private var expectedSealedBox: AddressBookSealedBox {
        AddressBookSealedBox(
            nonce: Data(hexString: Self.nonceHex),
            ciphertext: Data(hexString: Self.ciphertextHex),
            tag: Data(hexString: Self.tagHex)
        )
    }

    private func makeEnvelope() -> AddressBookEnvelope {
        AddressBookEnvelope(version: "1.0", walletId: walletId, updatedAt: updatedAt, sealedBox: expectedSealedBox)
    }
}

// MARK: - Test doubles

private enum TestError: Error {
    case boom
}

private final class MockTangemApiService: TangemApiService {
    private(set) var syncRequests: [AddressBookDTO.SyncRequest] = []
    private(set) var updateCalls: [(walletId: String, knownETag: String?, body: AddressBookDTO.UpdateRequest)] = []

    var syncResult: Result<AddressBookDTO.Response, Error> = .failure(TestError.boom)
    var updateResult: Result<AddressBookDTO.UpdateResponse, Error> = .failure(TestError.boom)

    func syncAddressBooks(_ request: AddressBookDTO.SyncRequest) async throws -> AddressBookDTO.Response {
        syncRequests.append(request)
        return try syncResult.get()
    }

    func updateAddressBook(walletId: String, knownETag: String?, body: AddressBookDTO.UpdateRequest) async throws -> AddressBookDTO.UpdateResponse {
        updateCalls.append((walletId, knownETag, body))
        return try updateResult.get()
    }

    // MARK: Unused endpoints — not reachable from the unit under test.

    func getRawData(fromURL url: URL) async throws -> Data { fatalError("unused") }
    func subscribeToPriceAlerts(userWalletIds: [String], tokenId: String) async throws { fatalError("unused") }
    func unsubscribeFromPriceAlerts(userWalletIds: [String], tokenId: String) async throws { fatalError("unused") }
    func priceAlertsSubscriptions(userWalletId: String) async throws -> [String] { fatalError("unused") }
    func loadGeo() -> AnyPublisher<String, Error> { fatalError("unused") }
    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> { fatalError("unused") }
    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> { fatalError("unused") }
    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> { fatalError("unused") }
    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response { fatalError("unused") }
    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response { fatalError("unused") }
    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response { fatalError("unused") }
    func loadCoinsHistoryChartPreview(requestModel: MarketsDTO.ChartsHistory.PreviewRequest) async throws -> MarketsDTO.ChartsHistory.PreviewResponse { fatalError("unused") }
    func loadHistoryChart(requestModel: MarketsDTO.ChartsHistory.HistoryRequest) async throws -> MarketsDTO.ChartsHistory.HistoryResponse { fatalError("unused") }
    func loadTokenExchangesListDetails(requestModel: MarketsDTO.ExchangesRequest) async throws -> MarketsDTO.ExchangesResponse { fatalError("unused") }
    func loadEarnYieldMarkets(requestModel: EarnDTO.List.Request) async throws -> EarnDTO.List.Response { fatalError("unused") }
    func loadEarnNetworks(requestModel: EarnDTO.Networks.Request) async throws -> EarnDTO.Networks.Response { fatalError("unused") }
    func loadCoinsSettings() async throws -> CoinsSettingsDTO.Response { fatalError("unused") }
    func loadNewsList(requestModel: NewsDTO.List.Request) async throws -> NewsDTO.List.Response { fatalError("unused") }
    func loadNewsDetails(requestModel: NewsDTO.Details.Request) async throws -> NewsDTO.Details.Response { fatalError("unused") }
    func loadNewsCategories() async throws -> NewsDTO.Categories.Response { fatalError("unused") }
    func loadTrendingNews(limit: Int?, lang: String?) async throws -> TrendingNewsResponse { fatalError("unused") }
    func saveTokens(list: AccountsDTO.Request.UserTokens, for key: String) async throws { fatalError("unused") }
    func saveTokensV2(list: AccountsDTO.Request.UserTokens, for key: String) async throws { fatalError("unused") }
    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response { fatalError("unused") }
    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError> { fatalError("unused") }
    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo { fatalError("unused") }
    func participateInReferralProgram(using token: AwardToken, for address: String, with userWalletId: String) async throws -> ReferralProgramInfo { fatalError("unused") }
    func bindReferral(request model: ReferralDTO.Request) async throws { fatalError("unused") }
    func activatePromoCode(request model: PromoCodeActivationDTO.Request) -> AnyPublisher<PromoCodeActivationDTO.Response, TangemAPIError> { fatalError("unused") }
    func loadStory(storyId: String) async throws -> StoryDTO.Response { fatalError("unused") }
    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response { fatalError("unused") }
    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response { fatalError("unused") }
    func loadPromotionCampaigns(userWalletId: String) async throws -> [BannerPromotion.Response.Promotion] { fatalError("unused") }
    func loadYieldBoostPromotionStatus(userWalletId: String) async throws -> YieldBoostPromotionDTO.Response { fatalError("unused") }
    func loadMarketingCampaigns(request: MarketingCampaignsDTO.Request) async throws -> MarketingCampaignsDTO.Response { fatalError("unused") }
    func loadFeatures() async throws -> [String: Bool] { fatalError("unused") }
    func loadAPIList() async throws -> APIListDTO { fatalError("unused") }
    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem] { fatalError("unused") }
    func getNotificationPreferences(userWalletId: String) async throws -> NotificationPreferencesDTO.Body { fatalError("unused") }
    func updateNotificationPreferences(userWalletId: String, preferences: NotificationPreferencesDTO.Body) async throws { fatalError("unused") }
    func createUserWalletsApplications(requestModel: ApplicationDTO.Request) async throws -> ApplicationDTO.Create.Response { fatalError("unused") }
    func updateUserWalletsApplications(uid: String, requestModel: ApplicationDTO.Update.Request) async throws { fatalError("unused") }
    func connectUserWallets(uid: String, requestModel: ApplicationDTO.Connect.Request) async throws { fatalError("unused") }
    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response] { fatalError("unused") }
    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response { fatalError("unused") }
    func updateWallet(by userWalletId: String, context: some Encodable) async throws { fatalError("unused") }
    func createWallet(with context: some Encodable) async throws -> String? { fatalError("unused") }
    func getUserAccounts(userWalletId: String) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) { fatalError("unused") }
    func saveUserAccounts(userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) { fatalError("unused") }
    func getArchivedUserAccounts(userWalletId: String) async throws -> AccountsDTO.Response.ArchivedAccounts { fatalError("unused") }
}
