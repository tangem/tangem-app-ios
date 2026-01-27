//
//  CommonTangemApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import Moya
import BlockchainSdk
import TangemFoundation
import TangemNetworkUtils

class CommonTangemApiService {
    private let provider = TangemProvider<TangemApiTarget>(plugins: [
        CachePolicyPlugin(),
        TimeoutIntervalPlugin(),
        DeviceInfoPlugin(),
        TangemNetworkLoggerPlugin(logOptions: .verbose),
        TangemNetworkAnalyticsPlugin(),
        TangemApiAuthorizationPlugin(),
    ])

    private let coinsQueue = DispatchQueue(label: "coins_request_queue", qos: .default)
    private let currenciesQueue = DispatchQueue(label: "currencies_request_queue", qos: .default)

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    deinit {
        AppLogger.debug(self)
    }

    private func request<D: Decodable>(for type: TangemApiTarget.TargetType, decoder: JSONDecoder = .init()) async throws -> D {
        let target = TangemApiTarget(type: type)

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)

            return try response.mapAPIResponseThrowingTangemAPIError(allowRedirectCodes: false, decoder: decoder)
        }
    }

    private func requestRawData(for type: TangemApiTarget.TargetType) async throws -> Data {
        let target = TangemApiTarget(type: type)

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)

            return response.data
        }
    }

    private func withErrorLoggingPipeline<T>(target: TangemApiTarget, work: () async throws -> T) async rethrows -> T {
        do {
            return try await work()
        } catch let error as MoyaError {
            log(error: error, exceptionHost: target.requestDescription, code: error.errorCode.description)
            throw error
        } catch let error as TangemAPIError {
            log(error: error, exceptionHost: target.requestDescription, code: error.code.description ?? .empty)
            throw error
        } catch {
            log(error: error, exceptionHost: target.requestDescription, code: TangemAPIError.ErrorCode.unknown.description ?? .empty)
            throw error
        }
    }
}

// MARK: - TangemApiService

extension CommonTangemApiService: TangemApiService {
    func getRawData(fromURL url: URL) async throws -> Data {
        try await requestRawData(for: .rawData(url: url))
    }

    func loadGeo() -> AnyPublisher<String, any Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .geo))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .eraseError()
            .eraseToAnyPublisher()
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError> {
        let target = TangemApiTarget(type: .getUserWalletTokens(key: key))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(UserTokenList?.self)
            .mapTangemAPIError()
            .catch { error -> AnyPublisher<UserTokenList?, TangemAPIError> in
                if error.code == .notFound {
                    return Just(nil)
                        .setFailureType(to: TangemAPIError.self)
                        .eraseToAnyPublisher()
                }

                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .retry(3)
            .eraseToAnyPublisher()
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        let target = TangemApiTarget(type: .saveUserWalletTokensLegacy(key: key, list: list))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .mapTangemAPIError()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func saveTokens(list: AccountsDTO.Request.UserTokens, for key: String) async throws {
        let target = TangemApiTarget(type: .saveUserWalletTokens(key: key, list: list))

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            // An empty response (just zero bytes, not "{}", "[{}]" or similar) can't be mapped
            // into the `EmptyGenericResponseDTO` DTO, therefore we just check for errors and status codes here
            let _ = try response.filterResponseThrowingTangemAPIError(allowRedirectCodes: true)
        }
    }

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError> {
        let parameters = BlockchainAccountCreateParameters(networkId: networkId, walletPublicKey: publicKey)
        let target = TangemApiTarget(type: .createAccount(parameters))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(BlockchainAccountCreateResult.self)
            .mapTangemAPIError()
            .eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .coins(requestModel)))
            .filterSuccessfulStatusCodes()
            .map(CoinsList.Response.self)
            .eraseError()
            .map { response in
                let mapper = CoinsResponseMapper(supportedBlockchains: requestModel.supportedBlockchains)
                let coinModels = mapper.mapToCoinModels(response)

                guard let contractAddress = requestModel.contractAddress else {
                    return coinModels
                }

                return coinModels.compactMap { coinModel in
                    let items = coinModel.items.filter { item in
                        item.token?.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
                    }

                    guard !items.isEmpty else {
                        return nil
                    }

                    return CoinModel(
                        id: coinModel.id,
                        name: coinModel.name,
                        symbol: coinModel.symbol,
                        items: items
                    )
                }
            }
            .subscribe(on: coinsQueue)
            .eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response {
        return try await request(for: .coins(requestModel), decoder: decoder)
    }

    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> {
        let target = TangemApiTarget(type: .quotes(requestModel))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(QuotesDTO.Response.self)
            .eraseError()
            .map { response in
                QuotesMapper().mapToQuotes(response)
            }
            .eraseToAnyPublisher()
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .currencies))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name }) }
            .mapError { _ in AppError.serverUnavailable }
            .subscribe(on: currenciesQueue)
            .eraseToAnyPublisher()
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        let target = TangemApiTarget(
            type: .loadReferralProgramInfo(userWalletId: userWalletId, expectedAwardsLimit: expectedAwardsLimit)
        )

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()

            return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
        }
    }

    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo {
        let userInfo = ReferralParticipationRequestBody(
            walletId: userWalletId,
            networkId: token.networkId,
            tokenId: token.id,
            address: address
        )
        let target = TangemApiTarget(
            type: .participateInReferralProgram(userInfo: userInfo)
        )

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()

            return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
        }
    }

    func bindReferral(request model: ReferralDTO.Request) async throws {
        let target = TangemApiTarget(type: .bindWalletsByCode(model))

        try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            _ = try response.filterSuccessfulStatusAndRedirectCodes()
        }
    }

    func expressPromotion(request model: ExpressPromotion.Request) async throws -> ExpressPromotion.Response {
        return try await request(for: .promotion(request: model), decoder: decoder)
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        try await request(for: .promotion(request: .init(programName: programName)))
    }

    func activatePromoCode(request model: PromoCodeActivationDTO.Request) -> AnyPublisher<PromoCodeActivationDTO.Response, TangemAPIError> {
        let target = TangemApiTarget(type: .activatePromoCode(requestModel: model))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(PromoCodeActivationDTO.Response.self)
            .mapTangemAPIError()
            .eraseToAnyPublisher()
    }

    @discardableResult
    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult {
        try await request(for: .validateNewUserPromotionEligibility(walletId: walletId, code: code))
    }

    @discardableResult
    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult {
        try await request(for: .validateOldUserPromotionEligibility(walletId: walletId, programName: programName))
    }

    @discardableResult
    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult {
        try await request(for: .awardNewUser(walletId: walletId, address: address, code: code))
    }

    @discardableResult
    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult {
        try await request(for: .awardOldUser(walletId: walletId, address: address, programName: programName))
    }

    @discardableResult
    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult {
        try await request(for: .resetAward(cardId: cardId))
    }

    func loadStory(storyId: String) async throws -> StoryDTO.Response {
        try await request(for: .story(storyId))
    }

    func loadAPIList() async throws -> APIListDTO {
        try await request(for: .apiList)
    }

    func loadFeatures() async throws -> [String: Bool] {
        try await request(for: .features)
    }

    // MARK: - Markets Implementation

    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response {
        return try await request(for: .coinsList(requestModel), decoder: decoder)
    }

    func loadCoinsHistoryChartPreview(
        requestModel: MarketsDTO.ChartsHistory.PreviewRequest
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse {
        return try await request(for: .coinsHistoryChartPreview(requestModel), decoder: decoder)
    }

    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response {
        return try await request(for: .tokenMarketsDetails(requestModel), decoder: decoder)
    }

    func loadHistoryChart(
        requestModel: MarketsDTO.ChartsHistory.HistoryRequest
    ) async throws -> MarketsDTO.ChartsHistory.HistoryResponse {
        return try await request(for: .historyChart(requestModel), decoder: decoder)
    }

    func loadTokenExchangesListDetails(
        requestModel: MarketsDTO.ExchangesRequest
    ) async throws -> MarketsDTO.ExchangesResponse {
        return try await request(for: .tokenExchangesList(requestModel), decoder: decoder)
    }

    // MARK: - Earn Implementation

    func loadEarnYieldMarkets(requestModel: EarnDTO.List.Request) async throws -> EarnDTO.List.Response {
        return try await request(for: .earnYieldMarkets(requestModel), decoder: decoder)
    }

    // MARK: - Action Buttons

    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response {
        try await request(for: .hotCrypto(requestModel))
    }

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO {
        return try await request(for: .seedNotifyGetStatus(userWalletId: userWalletId), decoder: decoder)
    }

    func getSeedNotifyStatusConfirmed(userWalletId: String) async throws -> SeedNotifyDTO {
        return try await request(for: .seedNotifyGetStatusConfirmed(userWalletId: userWalletId), decoder: decoder)
    }

    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws {
        let target: TangemApiTarget.TargetType = .seedNotifySetStatus(userWalletId: userWalletId, status: status)
        let _: EmptyGenericResponseDTO = try await request(for: target, decoder: decoder)
    }

    func setSeedNotifyStatusConfirmed(userWalletId: String, status: SeedNotifyStatus) async throws {
        let target: TangemApiTarget.TargetType = .seedNotifySetStatusConfirmed(userWalletId: userWalletId, status: status)
        let _: EmptyGenericResponseDTO = try await request(for: target, decoder: decoder)
    }

    // MARK: - Notification

    func pushNotificationsEligibleNetworks() async throws -> [NotificationDTO.NetworkItem] {
        try await request(for: .pushNotificationsEligible, decoder: decoder)
    }

    // MARK: - Applications

    func createUserWalletsApplications(requestModel: ApplicationDTO.Request) async throws -> ApplicationDTO.Create.Response {
        let target: TangemApiTarget.TargetType = .createUserWalletsApplication(requestModel)
        return try await request(for: target, decoder: decoder)
    }

    func updateUserWalletsApplications(uid: String, requestModel: ApplicationDTO.Update.Request) async throws {
        let target: TangemApiTarget.TargetType = .updateUserWalletsApplication(uid: uid, requestModel: requestModel)
        let _: EmptyGenericResponseDTO = try await request(for: target, decoder: decoder)
    }

    func connectUserWallets(uid: String, requestModel: ApplicationDTO.Connect.Request) async throws {
        let target: TangemApiTarget.TargetType = .connectUserWallets(uid: uid, requestModel: requestModel)
        let _: EmptyGenericResponseDTO = try await request(for: target, decoder: decoder)
    }

    // MARK: - UserWallets

    func getUserWallets(applicationUid: String) async throws -> [UserWalletDTO.Response] {
        try await request(for: .getUserWallets(applicationUid: applicationUid), decoder: decoder)
    }

    func getUserWallet(userWalletId: String) async throws -> UserWalletDTO.Response {
        try await request(for: .getUserWallet(userWalletId: userWalletId), decoder: decoder)
    }

    func updateWallet(by userWalletId: String, context: some Encodable) async throws {
        let target: TangemApiTarget.TargetType = .updateWallet(userWalletId: userWalletId, context: context)
        let _: EmptyGenericResponseDTO = try await request(for: target, decoder: decoder)
    }

    func createWallet(with context: some Encodable) async throws -> String? {
        let target = TangemApiTarget(type: .createWallet(context: context))

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            let revision = response.response?.value(forHTTPHeaderField: TangemAPIHeaders.eTag.rawValue)
            let _: EmptyGenericResponseDTO = try response.mapAPIResponseThrowingTangemAPIError(
                allowRedirectCodes: true,
                decoder: decoder
            )

            return revision
        }
    }

    // MARK: - Accounts

    func getUserAccounts(
        userWalletId: String
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) {
        let target = TangemApiTarget(type: .getUserAccounts(userWalletId: userWalletId))

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            let revision = response.response?.value(forHTTPHeaderField: TangemAPIHeaders.eTag.rawValue)
            let accounts: AccountsDTO.Response.Accounts = try response.mapAPIResponseThrowingTangemAPIError(
                allowRedirectCodes: true,
                decoder: decoder
            )

            return (revision: revision, accounts: accounts)
        }
    }

    func saveUserAccounts(
        userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts
    ) async throws -> (revision: String?, accounts: AccountsDTO.Response.Accounts) {
        let target = TangemApiTarget(type: .saveUserAccounts(userWalletId: userWalletId, revision: revision, accounts: accounts))

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            let revision = response.response?.value(forHTTPHeaderField: TangemAPIHeaders.eTag.rawValue)
            let accounts: AccountsDTO.Response.Accounts = try response.mapAPIResponseThrowingTangemAPIError(
                allowRedirectCodes: true,
                decoder: decoder
            )

            return (revision: revision, accounts: accounts)
        }
    }

    func getArchivedUserAccounts(userWalletId: String) async throws -> AccountsDTO.Response.ArchivedAccounts {
        let target = TangemApiTarget(type: .getArchivedUserAccounts(userWalletId: userWalletId))

        return try await withErrorLoggingPipeline(target: target) {
            let response = try await provider.asyncRequest(target)
            return try response.mapAPIResponseThrowingTangemAPIError(allowRedirectCodes: true, decoder: decoder)
        }
    }

    // MARK: - News Implementation

    func loadTrendingNews(limit: Int?, lang: String?) async throws -> TrendingNewsResponse {
        return try await request(for: .trendingNews(limit: limit, lang: lang), decoder: decoder)
    }

    func loadNewsList(requestModel: NewsDTO.List.Request) async throws -> NewsDTO.List.Response {
        return try await request(for: .newsList(requestModel), decoder: decoder)
    }

    func loadNewsCategories() async throws -> NewsDTO.Categories.Response {
        return try await request(for: .newsCategories, decoder: decoder)
    }
}

// MARK: - Analytics

private extension CommonTangemApiService {
    func log(error: Error, exceptionHost: String, code: String) {
        Analytics.log(
            event: .tangemAPIException,
            params: [
                .exceptionHost: exceptionHost,
                .errorCode: code,
                .errorMessage: error.localizedDescription,
            ],
            analyticsSystems: [.firebase, .crashlytics]
        )
    }
}

// MARK: - Auxiliary types

/// Used when the API returns an empty response with 200 status code.
/// Using `Never` since Swift 5.9 could be an alternative, but its decoding throws an error unconditionally,
/// see https://github.com/swiftlang/swift-evolution/blob/main/proposals/0396-never-codable.md for details.
private extension CommonTangemApiService {
    struct EmptyGenericResponseDTO: Decodable {}
}
