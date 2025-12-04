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

    // MARK: - User token list management

    @available(iOS, deprecated: 100000.0, message: "Superseded by 'getUserAccounts(userWalletId:)', will be removed in the future ([REDACTED_INFO])")
    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError>

    @available(iOS, deprecated: 100000.0, message: "Superseded by the async version of 'saveTokens(list:for:)', will be removed in the future ([REDACTED_INFO])")
    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError>

    func saveTokens(list: AccountsDTO.Request.UserTokens, for key: String) async throws

    // MARK: - Action Buttons

    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response

    // MARK: - BSDK

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError>

    // MARK: - Promotions and awards

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo
    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo

    func expressPromotion(request: ExpressPromotion.Request) async throws -> ExpressPromotion.Response
    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters

    @discardableResult
    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult
    @discardableResult
    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult
    @discardableResult
    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult
    @discardableResult
    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult
    @discardableResult
    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult

    func activatePromoCode(request model: PromoCodeActivationDTO.Request) -> AnyPublisher<PromoCodeActivationDTO.Response, TangemAPIError>

    func loadStory(storyId: String) async throws -> StoryDTO.Response

    // MARK: - Seed Notify

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO
    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws
    func getSeedNotifyStatusConfirmed(userWalletId: String) async throws -> SeedNotifyDTO
    func setSeedNotifyStatusConfirmed(userWalletId: String, status: SeedNotifyStatus) async throws

    // MARK: - Configs

    func loadFeatures() async throws -> [String: Bool]

    func loadAPIList() async throws -> APIListDTO

    // MARK: - Notification

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem]

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
    /// - Returns: Array of user wallet details including ID, name and notification status
    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response]

    /// Retrieves details for a specific user wallet
    /// - Returns: User wallet details including ID, name and notification status
    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response

    /// Update user wallet data model
    func updateWallet(by userWalletId: String, context: some Encodable) async throws

    /// - Returns: New revision for optimistic locking.
    func createWallet(with context: some Encodable) async throws -> String?

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
