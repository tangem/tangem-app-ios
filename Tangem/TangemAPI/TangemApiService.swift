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

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError>
    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError>

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

    func loadStory(storyId: String) async throws -> StoryDTO.Response

    // MARK: - Seed Notify

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO
    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws
    func getSeedNotifyStatusConfirmed(userWalletId: String) async throws -> SeedNotifyDTO
    func setSeedNotifyStatusConfirmed(userWalletId: String, status: SeedNotifyStatus) async throws
    func setWalletInitialized(userWalletId: String) async throws

    // MARK: - Configs

    func loadFeatures() async throws -> [String: Bool]

    func loadAPIList() async throws -> APIListDTO

    // MARK: - Notification

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem]

    // MARK: - Applications

    /// Create application with new uid
    func createUserWalletsApplications(requestModel: ApplicationDTO.Request) async throws -> ApplicationDTO.Create.Response

    /// Update application with new uid with pushToken
    @discardableResult
    func updateUserWalletsApplications(uid: String, requestModel: ApplicationDTO.Update.Request) async throws -> EmptyGenericResponseDTO

    // MARK: - UserWallets

    /// Retrieves all user wallets associated with the given application ID
    /// - Returns: Array of user wallet details including ID, name and notification status
    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response]

    /// Retrieves details for a specific user wallet
    /// - Returns: User wallet details including ID, name and notification status
    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response

    /// Update user wallet data model
    @discardableResult
    func updateUserWallet(by userWalletId: String, requestModel: UserWalletDTO.Update.Request) async throws -> EmptyGenericResponseDTO

    /// Creates a new user wallet and associates it with the given application
    /// - Parameters:
    ///   - requestModel: Details for creating the new wallet including ID and name
    /// - Returns: Empty response indicating success
    @discardableResult
    func createAndConnectUserWallet(applicationUid: String, items: [UserWalletDTO.Create.Request]) async throws -> EmptyGenericResponseDTO
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
