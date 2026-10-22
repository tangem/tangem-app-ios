//
//  TangemApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TangemApiService: AnyObject {
    func getRawData(fromURL url: URL) async throws -> Data

    // MARK: - Geo

    func loadGeo() -> AnyPublisher<String, Error>

    // MARK: - Coins and quotes

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error>
    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error>
    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error>

    /// Copy loadCoins request via async await
    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response

    // MARK: - Markets

    /// Get general market data for a list of tokens
    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response

    func loadCoinsCategories(requestModel: MarketsDTO.Categories.Request) async throws -> MarketsDTO.Categories.Response
    func loadCoinsGeckoCategories(requestModel: MarketsDTO.GeckoCategories.Request) async throws -> MarketsDTO.GeckoCategories.Response
    func loadMarketIndicators(requestModel: MarketsDTO.MarketIndicators.Request) async throws -> MarketsDTO.MarketIndicators.Response

    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response

    /// Get preview history chart data for a list of tokens
    func loadCoinsHistoryChartPreview(
        requestModel: MarketsDTO.ChartsHistory.PreviewRequest
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse

    /// Get detail history chart data for a given token
    func loadHistoryChart(
        requestModel: MarketsDTO.ChartsHistory.HistoryRequest
    ) async throws -> MarketsDTO.ChartsHistory.HistoryResponse

    func loadTokenExchangesListDetails(requestModel: MarketsDTO.ExchangesRequest) async throws -> MarketsDTO.ExchangesResponse

    // MARK: - Earn

    func loadEarnYieldMarkets(requestModel: EarnDTO.List.Request) async throws -> EarnDTO.List.Response
    func loadEarnNetworks(requestModel: EarnDTO.Networks.Request) async throws -> EarnDTO.Networks.Response

    // MARK: - Coins

    func loadCoinsSettings() async throws -> CoinsSettingsDTO.Response

    func loadCoinIndicators(requestModel: CoinIndicatorsDTO.Request) async throws -> CoinIndicatorsDTO.Response

    // MARK: - News

    func loadNewsList(requestModel: NewsDTO.List.Request) async throws -> NewsDTO.List.Response
    func loadNewsDetails(requestModel: NewsDTO.Details.Request) async throws -> NewsDTO.Details.Response
    func loadNewsCategories() async throws -> NewsDTO.Categories.Response

    // MARK: - User token list management

    /// Locked the way saving the accounts is: a token list a joint account has is one list for every member, and
    /// without the lock two of them writing it overwrite each other.
    /// - Parameter revision: The accounts ETag, sent as `If-Match`.
    /// - Returns: The fresh ETag, whenever the endpoint reports one back.
    func saveTokensV2(list: AccountsDTO.Request.UserTokens, for key: String, revision: String) async throws -> String?

    // MARK: - Action Buttons

    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response

    // MARK: - BSDK

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError>

    // MARK: - Awards

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo
    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo

    func bindReferral(request model: ReferralDTO.Request) async throws

    func activatePromoCode(request model: PromoCodeActivationDTO.Request) -> AnyPublisher<PromoCodeActivationDTO.Response, TangemAPIError>

    func loadStory(storyId: String) async throws -> StoryDTO.Response

    func loadStories(slugs: [String], language: String) async throws -> StoriesResponseDTO

    // MARK: - Promotions

    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response
    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response

    // MARK: - Promo campaigns

    func loadPromoCampaigns(request: PromoCampaignsDTO.Request) async throws -> [PromoCampaignsDTO.Promotion]
    func enrollInPromoCampaign(id: Int, request: PromoCampaignEnrollmentDTO.Request) async throws -> PromoCampaignEnrollmentDTO.Response

    // MARK: - Yield Boost Promotion

    func loadPromotionCampaigns(userWalletId: String) async throws -> [BannerPromotion.Response.Promotion]
    func loadYieldBoostPromotionStatus(userWalletId: String) async throws -> YieldBoostPromotionDTO.Response
    func registerForPromotionCampaign(request: PromotionRegistrationDTO.Request) async throws -> PromotionRegistrationDTO.Response

    // MARK: - Application versions

    func loadApplicationVersions() async throws -> ApplicationVersionsDTO

    // MARK: - Marketing

    func loadMarketingCampaigns(request: MarketingCampaignsDTO.Request) async throws -> MarketingCampaignsDTO.Response

    // MARK: - Configs

    func loadFeatures() async throws -> [String: Bool]

    func loadAPIList() async throws -> APIListDTO

    // MARK: - Notification

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem]

    // MARK: - Notification Preferences

    func getNotificationPreferences(userWalletId: String) async throws -> NotificationPreferencesDTO.Body
    func updateNotificationPreferences(
        userWalletId: String,
        preferences: NotificationPreferencesDTO.Body
    ) async throws

    // MARK: - Price Alerts Subscriptions

    func subscribeToPriceAlerts(userWalletIds: [String], tokenId: String) async throws
    func unsubscribeFromPriceAlerts(userWalletIds: [String], tokenId: String) async throws
    /// Returns the `tokenId` values the wallet is subscribed to.
    func priceAlertsSubscriptions(userWalletId: String) async throws -> [String]

    // MARK: - Applications

    /// Create application with new uid
    func createUserWalletsApplications(requestModel: ApplicationDTO.Request) async throws -> ApplicationDTO.Create.Response

    /// Update application with new uid with pushToken
    func updateUserWalletsApplications(uid: String, requestModel: ApplicationDTO.Update.Request) async throws

    /// Creates a new user wallet and associates it with the given application
    /// - Parameters:
    ///   - requestModel: Details for connecting user wallets
    func connectUserWallets(uid: String, requestModel: ApplicationDTO.Connect.Request) async throws

    // MARK: - UserWallets

    /// Retrieves all user wallets associated with the given application ID
    /// - Returns: Array of user wallet details including ID and optional name
    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response]

    /// Retrieves details for a specific user wallet
    /// - Returns: User wallet details including ID and name
    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response

    /// Update user wallet data model
    func updateWallet(by userWalletId: String, context: some Encodable) async throws

    /// - Returns: New revision for optimistic locking.
    func createWallet(with context: some Encodable) async throws -> String?

    // MARK: - Wallet Backup Status

    /// Reports the known cards and their backup state for a wallet.
    func saveWalletCards(userWalletId: String, cards: WalletCardsDTO.Request) async throws

    // MARK: - Accounts

    /// - Returns: New revision for optimistic locking and the list of active accounts.
    func getUserAccounts(
        userWalletId: String
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts)

    /// - Returns: New revision for optimistic locking and the list of active accounts.
    func saveUserAccounts(
        userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts)

    /// - Returns: The list of archived accounts.
    func getArchivedUserAccounts(userWalletId: String) async throws -> AccountsDTO.Response.ArchivedAccounts

    // MARK: - Joint accounts

    /// - Returns: Every joint account the wallet takes part in
    /// - Parameter knownETag: The tag the list was last read with, sent as `If-None-Match`; nil reads it outright.
    /// - Returns: nil when the list has not changed since that tag, which the endpoint says with a 304 and no body;
    /// otherwise the list and the tag it came with, to be sent back the next time.
    func getJointAccounts(
        walletId: String, knownETag: String?
    ) async throws -> (eTag: String?, accounts: JointAccountsDTO.Response.JointAccounts)?

    /// - Returns: The account, in `pending` with the caller as its creator, and one invite per free slot.
    func createJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Create
    ) async throws -> JointAccountsDTO.Response.JointAccount

    /// - Returns: What the invited wallet is joining and who is inviting it.
    /// - Note: The wallet in the path is the one the invite is being checked for, so a wallet that already holds a slot
    /// is turned away here rather than after the card has been tapped.
    func getJointAccountInvite(
        walletId: String, inviteId: String
    ) async throws -> JointAccountsDTO.Response.InvitePreview

    func joinJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Join
    ) async throws -> JointAccountsDTO.Response.JointAccount

    func activateJointAccount(
        walletId: String, body: JointAccountsDTO.Request.Activate
    ) async throws -> JointAccountsDTO.Response.JointAccount

    /// - Returns: The operation, in `awaiting_signatures` with the initiator's signature already counted — or in
    /// `pending` right away when the account's threshold is 1.
    func createJointAccountOperation(
        walletId: String, body: JointAccountsDTO.Request.CreateOperation
    ) async throws -> JointAccountsDTO.Response.Operation

    /// - Returns: The operation with the caller's signature counted in; reaching the threshold hands it to the relayer.
    func signJointAccountOperation(
        walletId: String, operationId: String, body: JointAccountsDTO.Request.SignOperation
    ) async throws -> JointAccountsDTO.Response.Operation

    /// Neither signed nor given a body: which of the two refusals it is follows from the wallet it is called for.
    /// - Returns: The operation with its progress recounted, or nil when it no longer collects answers at all — this
    /// call finished it, an earlier one did, or the id names nothing.
    func rejectJointAccountOperation(
        walletId: String, operationId: String
    ) async throws -> JointAccountsDTO.Response.Operation?

    func getJointOperationsHistory(
        walletId: String, request: JointAccountsDTO.Request.OperationsHistory
    ) async throws -> JointAccountsDTO.Response.OperationsHistory

    func getJointOperationsHistoryDelta(
        walletId: String, request: JointAccountsDTO.Request.OperationsHistoryDelta
    ) async throws -> JointAccountsDTO.Response.OperationsHistoryDelta

    func getJointOperation(
        walletId: String, operationId: String, knownETag: String?
    ) async throws -> (eTag: String?, operation: JointAccountsDTO.Response.HistoryOperation)?

    // MARK: - Address Book

    /// Fetches the encrypted books of the requested wallets, skipping any whose sent etag still matches.
    func syncAddressBooks(_ request: AddressBookDTO.SyncRequest) async throws -> AddressBookDTO.Response

    /// Replaces a wallet's encrypted book, optimistically locked by `knownETag` (omitted on first write).
    /// - Returns: The PUT response body — the new etag, used as the next `If-Match`.
    func updateAddressBook(walletId: String, knownETag: String?, body: AddressBookDTO.UpdateRequest) async throws -> AddressBookDTO.UpdateResponse
}

private struct TangemApiServiceKey: InjectionKey {
    static var currentValue: TangemApiService = CommonTangemApiService()
}

extension InjectedValues {
    var tangemApiService: TangemApiService {
        get { Self[TangemApiServiceKey.self] }
        set { Self[TangemApiServiceKey.self] = newValue }
    }
}
