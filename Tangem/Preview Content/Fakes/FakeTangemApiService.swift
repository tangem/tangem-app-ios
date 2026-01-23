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

final class FakeTangemApiService: TangemApiService {
    private let geoIpRegionCode: String

    init(geoIpRegionCode: String = "us") {
        self.geoIpRegionCode = geoIpRegionCode
    }

    func getRawData(fromURL url: URL) async throws -> Data {
        throw "Not implemented"
    }

    func loadGeo() -> AnyPublisher<String, any Error> {
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
        let provider = FakeCoinListProvider()
        return try provider.parseCoinResponse()
    }

    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func saveTokens(list: AccountsDTO.Request.UserTokens, for key: String) async throws {
        throw "Not implemented"
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func participateInReferralProgram(using token: AwardToken, for address: String, with userWalletId: String) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func expressPromotion(request: ExpressPromotion.Request) async throws -> ExpressPromotion.Response {
        throw "Not implemented"
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        throw "Not implemented"
    }

    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult {
        throw "Not implemented"
    }

    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult {
        throw "Not implemented"
    }

    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult {
        throw "Not implemented"
    }

    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult {
        throw "Not implemented"
    }

    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult {
        throw "Not implemented"
    }

    func loadStory(storyId: String) async throws -> StoryDTO.Response {
        throw "Not implemented"
    }

    func loadAPIList() async throws -> APIListDTO {
        throw "Not implemented"
    }

    func loadFeatures() async throws -> [String: Bool] {
        throw "Not implemented"
    }

    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response {
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

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO {
        throw "Not implemented"
    }

    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws {
        throw "Not implemented"
    }

    func getSeedNotifyStatusConfirmed(userWalletId: String) async throws -> SeedNotifyDTO {
        throw "Not implemented"
    }

    func setSeedNotifyStatusConfirmed(userWalletId: String, status: SeedNotifyStatus) async throws {
        throw "Not implemented"
    }

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem] {
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

    func getYieldMarkets() async throws -> YieldModuleDTO.Response.MarketsInfo {
        throw "Not implemented"
    }

    func getTokenPositionInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleDTO.Response.PositionInfo {
        throw "Not implemented"
    }

    func bindReferral(request model: ReferralDTO.Request) async throws {
        throw "Not implemented"
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
