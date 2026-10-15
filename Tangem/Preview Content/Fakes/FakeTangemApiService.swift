//
//  FakeTangemApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

final class FakeTangemApiService: TangemApiService {
    private let geoIpRegionCode: String

    // MARK: - Geo Handlers (Tests/Previews)

    var loadGeoHandler: (@Sendable () async throws -> String)?

    // MARK: - News Handlers (Tests/Previews)

    var loadNewsListHandler: ((NewsDTO.List.Request) async throws -> NewsDTO.List.Response)?
    var loadNewsDetailsHandler: ((NewsDTO.Details.Request) async throws -> NewsDTO.Details.Response)?
    var loadNewsCategoriesHandler: (() async throws -> NewsDTO.Categories.Response)?

    // MARK: - Coins Handlers (Tests/Previews)

    var loadCoinsHandler: ((CoinsList.Request) async throws -> CoinsList.Response)?
    var loadCoinsCategoriesHandler: ((MarketsDTO.Categories.Request) async throws -> MarketsDTO.Categories.Response)?
    var loadCoinsGeckoCategoriesHandler: ((MarketsDTO.GeckoCategories.Request) async throws -> MarketsDTO.GeckoCategories.Response)?
    var loadMarketIndicatorsHandler: ((MarketsDTO.MarketIndicators.Request) async throws -> MarketsDTO.MarketIndicators.Response)?

    // MARK: - Campaigns Handlers (Tests/Previews)

    var loadMarketingCampaignsHandler: ((MarketingCampaignsDTO.Request) async throws -> MarketingCampaignsDTO.Response)?
    var loadPromotionCampaignsHandler: ((String) async throws -> [BannerPromotion.Response.Promotion])?
    var loadPromoCampaignsHandler: ((PromoCampaignsDTO.Request) async throws -> [PromoCampaignsDTO.Promotion])?
    var enrollInPromoCampaignHandler: ((Int, PromoCampaignEnrollmentDTO.Request) async throws -> PromoCampaignEnrollmentDTO.Response)?
    var loadYieldBoostPromotionStatusHandler: ((String) async throws -> YieldBoostPromotionDTO.Response)?
    var registerForPromotionCampaignHandler: ((PromotionRegistrationDTO.Request) async throws -> PromotionRegistrationDTO.Response)?

    // MARK: - Promotions Handlers (Tests/Previews)

    var loadPromotionsHandler: ((PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response)?

    // MARK: - Joint Accounts Handlers (Tests/Previews)

    var getJointAccountsHandler: ((_ knownETag: String?) async throws -> (eTag: String?, accounts: JointAccountsDTO.Response.JointAccounts)?)?
    var rejectJointAccountOperationHandler: ((_ operationId: String) async throws -> JointAccountsDTO.Response.Operation?)?

    init(geoIpRegionCode: String = "us") {
        self.geoIpRegionCode = geoIpRegionCode
    }

    func getRawData(fromURL url: URL) async throws -> Data {
        throw "Not implemented"
    }

    func loadGeo() -> AnyPublisher<String, any Error> {
        if let loadGeoHandler {
            return Future.async { try await loadGeoHandler() }.eraseToAnyPublisher()
        }

        return .justWithError(output: geoIpRegionCode)
    }

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> {
        let provider = FakeCoinListProvider()
        do {
            return .justWithError(output: try provider.parseCoinModels())
        } catch {
            return .anyFail(error: error)
        }
    }

    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response {
        if let loadCoinsHandler {
            return try await loadCoinsHandler(requestModel)
        }

        let provider = FakeCoinListProvider()
        return try provider.parseCoinResponse()
    }

    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        .anyFail(error: "Not implemented")
    }

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func saveTokensV2(list: AccountsDTO.Request.UserTokens, for key: String, revision: String) async throws -> String? {
        throw "Not implemented"
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func participateInReferralProgram(using token: AwardToken, for address: String, with userWalletId: String) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response {
        if let handler = loadPromotionsHandler {
            return try await handler(request)
        }

        throw "Not implemented"
    }

    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response {
        throw "Not implemented"
    }

    func loadPromoCampaigns(request: PromoCampaignsDTO.Request) async throws -> [PromoCampaignsDTO.Promotion] {
        if let handler = loadPromoCampaignsHandler {
            return try await handler(request)
        }

        throw "Not implemented"
    }

    func enrollInPromoCampaign(id: Int, request: PromoCampaignEnrollmentDTO.Request) async throws -> PromoCampaignEnrollmentDTO.Response {
        if let handler = enrollInPromoCampaignHandler {
            return try await handler(id, request)
        }

        throw "Not implemented"
    }

    func loadPromotionCampaigns(userWalletId: String) async throws -> [BannerPromotion.Response.Promotion] {
        if let handler = loadPromotionCampaignsHandler {
            return try await handler(userWalletId)
        }

        throw "Not implemented"
    }

    func loadYieldBoostPromotionStatus(userWalletId: String) async throws -> YieldBoostPromotionDTO.Response {
        if let handler = loadYieldBoostPromotionStatusHandler {
            return try await handler(userWalletId)
        }

        throw "Not implemented"
    }

    func registerForPromotionCampaign(request: PromotionRegistrationDTO.Request) async throws -> PromotionRegistrationDTO.Response {
        if let handler = registerForPromotionCampaignHandler {
            return try await handler(request)
        }

        throw "Not implemented"
    }

    func loadMarketingCampaigns(request: MarketingCampaignsDTO.Request) async throws -> MarketingCampaignsDTO.Response {
        if let handler = loadMarketingCampaignsHandler {
            return try await handler(request)
        }

        throw "Not implemented"
    }

    func loadStory(storyId: String) async throws -> StoryDTO.Response {
        throw "Not implemented"
    }

    func loadStories(slugs: [String], language: String) async throws -> StoriesResponseDTO {
        throw "Not implemented"
    }

    func loadAPIList() async throws -> APIListDTO {
        throw "Not implemented"
    }

    func loadFeatures() async throws -> [String: Bool] {
        throw "Not implemented"
    }

    func loadApplicationVersions() async throws -> ApplicationVersionsDTO {
        throw "Not implemented"
    }

    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response {
        throw "Not implemented"
    }

    func loadCoinsCategories(requestModel: MarketsDTO.Categories.Request) async throws -> MarketsDTO.Categories.Response {
        if let loadCoinsCategoriesHandler {
            return try await loadCoinsCategoriesHandler(requestModel)
        }

        throw "Not implemented"
    }

    func loadCoinsGeckoCategories(requestModel: MarketsDTO.GeckoCategories.Request) async throws -> MarketsDTO.GeckoCategories.Response {
        if let loadCoinsGeckoCategoriesHandler {
            return try await loadCoinsGeckoCategoriesHandler(requestModel)
        }

        throw "Not implemented"
    }

    func loadMarketIndicators(requestModel: MarketsDTO.MarketIndicators.Request) async throws -> MarketsDTO.MarketIndicators.Response {
        if let loadMarketIndicatorsHandler {
            return try await loadMarketIndicatorsHandler(requestModel)
        }

        throw "Not implemented"
    }

    func loadCoinsHistoryChartPreview(
        requestModel: MarketsDTO.ChartsHistory.PreviewRequest
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse {
        throw "Not implemented"
    }

    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response {
        throw "Not implemented"
    }

    func loadHistoryChart(
        requestModel: MarketsDTO.ChartsHistory.HistoryRequest
    ) async throws -> MarketsDTO.ChartsHistory.HistoryResponse {
        throw "Not implemented"
    }

    func loadTokenExchangesListDetails(requestModel: MarketsDTO.ExchangesList.Request) async throws -> MarketsDTO.ExchangesList.Response {
        throw "Not implemented"
    }

    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response {
        throw "Not implemented"
    }

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem] {
        throw "Not implemented"
    }

    func getNotificationPreferences(userWalletId: String) async throws -> NotificationPreferencesDTO.Body {
        throw "Not implemented"
    }

    func updateNotificationPreferences(
        userWalletId: String,
        preferences: NotificationPreferencesDTO.Body
    ) async throws {
        throw "Not implemented"
    }

    func subscribeToPriceAlerts(userWalletIds: [String], tokenId: String) async throws {
        throw "Not implemented"
    }

    func unsubscribeFromPriceAlerts(userWalletIds: [String], tokenId: String) async throws {
        throw "Not implemented"
    }

    func priceAlertsSubscriptions(userWalletId: String) async throws -> [String] {
        throw "Not implemented"
    }

    func createUserWalletsApplications(requestModel: ApplicationDTO.Request) async throws -> ApplicationDTO.Create.Response {
        throw "Not implemented"
    }

    func updateUserWalletsApplications(uid: String, requestModel: ApplicationDTO.Update.Request) async throws {
        throw "Not implemented"
    }

    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response] {
        throw "Not implemented"
    }

    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response {
        throw "Not implemented"
    }

    func updateWallet(by userWalletId: String, context: some Encodable) async throws {
        throw "Not implemented"
    }

    func connectUserWallets(uid: String, requestModel: ApplicationDTO.Connect.Request) async throws {
        throw "Not implemented"
    }

    func activatePromoCode(request model: PromoCodeActivationDTO.Request) -> AnyPublisher<PromoCodeActivationDTO.Response, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func createWallet(with context: some Encodable) async throws -> String? {
        throw "Not implemented"
    }

    // MARK: - Wallet Backup Status

    func saveWalletCards(userWalletId: String, cards: WalletCardsDTO.Request) async throws {
        throw "Not implemented"
    }

    func getWalletCards(userWalletId: String) async throws -> WalletCardsDTO.Response {
        throw "Not implemented"
    }

    func getUserAccounts(
        userWalletId: String
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) {
        throw "Not implemented"
    }

    func saveUserAccounts(
        userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) {
        throw "Not implemented"
    }

    func getArchivedUserAccounts(userWalletId: String) async throws -> AccountsDTO.Response.ArchivedAccounts {
        throw "Not implemented"
    }

    func getJointAccounts(
        walletId: String, knownETag: String?
    ) async throws -> (eTag: String?, accounts: JointAccountsDTO.Response.JointAccounts)? {
        guard let getJointAccountsHandler else {
            throw "Not implemented"
        }

        return try await getJointAccountsHandler(knownETag)
    }

    func createJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Create
    ) async throws -> JointAccountsDTO.Response.JointAccount {
        throw "Not implemented"
    }

    func getJointAccountInvite(
        walletId: String, inviteId: String
    ) async throws -> JointAccountsDTO.Response.InvitePreview {
        throw "Not implemented"
    }

    func joinJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Join
    ) async throws -> JointAccountsDTO.Response.JointAccount {
        throw "Not implemented"
    }

    func activateJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Activate
    ) async throws -> JointAccountsDTO.Response.JointAccount {
        throw "Not implemented"
    }

    func createJointAccountOperation(
        walletId: String, body: JointAccountsDTO.Request.CreateOperation
    ) async throws -> JointAccountsDTO.Response.Operation {
        throw "Not implemented"
    }

    func signJointAccountOperation(
        walletId: String, operationId: String, body: JointAccountsDTO.Request.SignOperation
    ) async throws -> JointAccountsDTO.Response.Operation {
        throw "Not implemented"
    }

    func rejectJointAccountOperation(
        walletId: String, operationId: String
    ) async throws -> JointAccountsDTO.Response.Operation? {
        guard let rejectJointAccountOperationHandler else {
            throw "Not implemented"
        }

        return try await rejectJointAccountOperationHandler(operationId)
    }

    func syncAddressBooks(_ request: AddressBookDTO.SyncRequest) async throws -> AddressBookDTO.Response {
        throw "Not implemented"
    }

    func updateAddressBook(walletId: String, knownETag: String?, body: AddressBookDTO.UpdateRequest) async throws -> AddressBookDTO.UpdateResponse {
        throw "Not implemented"
    }

    func getYieldMarkets() async throws -> YieldModuleDTO.Response.MarketsInfo {
        throw "Not implemented"
    }

    func getTokenPositionInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleDTO.Response.PositionInfo {
        throw "Not implemented"
    }

    func loadNewsList(requestModel: NewsDTO.List.Request) async throws -> NewsDTO.List.Response {
        if let handler = loadNewsListHandler {
            return try await handler(requestModel)
        }

        throw "Not implemented"
    }

    func loadNewsDetails(requestModel: NewsDTO.Details.Request) async throws -> NewsDTO.Details.Response {
        if let handler = loadNewsDetailsHandler {
            return try await handler(requestModel)
        }

        throw "Not implemented"
    }

    func loadNewsCategories() async throws -> NewsDTO.Categories.Response {
        if let handler = loadNewsCategoriesHandler {
            return try await handler()
        }

        throw "Not implemented"
    }

    func bindReferral(request model: ReferralDTO.Request) async throws {
        throw "Not implemented"
    }

    func loadEarnYieldMarkets(requestModel: EarnDTO.List.Request) async throws -> EarnDTO.List.Response {
        try MockEarnProvider().loadEarnList()
    }

    func loadEarnNetworks(requestModel: EarnDTO.Networks.Request) async throws -> EarnDTO.Networks.Response {
        try MockEarnProvider().loadEarnNetworks()
    }

    func loadCoinsSettings() async throws -> CoinsSettingsDTO.Response {
        throw "Not implemented"
    }

    func loadCoinIndicators(requestModel: CoinIndicatorsDTO.Request) async throws -> CoinIndicatorsDTO.Response {
        CoinIndicatorsDTO.Response(assets: [])
    }
}

private struct MockEarnProvider {
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func loadEarnList() throws -> EarnDTO.List.Response {
        try JsonUtils.readBundleFile(with: "earnTokens", type: EarnDTO.List.Response.self, decoder: Self.decoder)
    }

    func loadEarnNetworks() throws -> EarnDTO.Networks.Response {
        try JsonUtils.readBundleFile(with: "earnNetworks", type: EarnDTO.Networks.Response.self, decoder: Self.decoder)
    }
}

private struct FakeCoinListProvider {
    func parseCoinModels() throws -> [CoinModel] {
        let response = try JsonUtils.readBundleFile(with: "coinsResponse", type: CoinsList.Response.self)
        let mapper = CoinsResponseMapper(supportedBlockchains: Set(Blockchain.allMainnetCases))
        let coinModels = mapper.mapToCoinModels(response)
        return coinModels
    }

    func parseCoinResponse() throws -> CoinsList.Response {
        try JsonUtils.readBundleFile(with: "coinsResponse", type: CoinsList.Response.self)
    }
}
