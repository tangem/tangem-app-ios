//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

struct TangemApiTarget: TargetType {
    let type: TargetType

    // MARK: - TargetType

    var baseURL: URL {
        switch type {
        case .rawData(let fullURL):
            fullURL
        case .activatePromoCode:
            AppEnvironment.current.activatePromoCodeBaseUrl
        case .promotion, .yieldBoostPromotionStatus:
            AppEnvironment.current.apiBaseUrlv2
        case .saveUserWalletTokensV2:
            // Contract v1.3 documents the full path as `/api/v2/wallets/{walletId}/tokens`.
            // NOTE: the leading `/api` segment is applied here but still needs backend confirmation
            // (gateway-internal vs. a real path). If BE serves `/v2/...` without `/api`, revert this
            // case back to `apiBaseUrlv2` — same caveat as notification-preferences below.
            AppEnvironment.current.apiBaseUrlv2WithGatewaySegment
        case .getNotificationPreferences, .updateNotificationPreferences:
            // Contract v1.3 documents the full path as `/api/v1/notification-preferences/{walletId}`.
            // NOTE: the leading `/api` segment is applied here but still needs backend confirmation.
            // If BE serves `/v1/...` without `/api`, revert this case back to `apiBaseUrl`.
            AppEnvironment.current.apiBaseUrlWithGatewaySegment
        default:
            AppEnvironment.current.apiBaseUrl
        }
    }

    var path: String {
        switch type {
        case .rawData:
            return ""
        case .currencies:
            return "/currencies"
        case .coins:
            return "/coins"
        case .quotes:
            return "/quotes"
        case .geo:
            return "/geo"
        case .features:
            return "/features"
        case .getUserWalletTokens(let key):
            return "/user-tokens/\(key)"
        case .saveUserWalletTokens(let key, _),
             .saveUserWalletTokensV2(let key, _):
            return "/wallets/\(key)/tokens"
        case .loadReferralProgramInfo(let userWalletId, _):
            return "/referral/\(userWalletId)"
        case .participateInReferralProgram:
            return "/referral"
        case .promotion:
            return "/promotion"
        case .yieldBoostPromotionStatus:
            return "/promotion/yield-apr-boost/status"
        case .loadPromotions:
            return "/banner/displays"
        case .hidePromotion(let request):
            return "/banner/displays/\(request.displayId)"
        case .marketingCampaigns:
            return "/marketing/campaigns"
        case .createAccount:
            return "/user-network-account"
        case .apiList:
            return "/networks/providers"
        case .story(let storyId):
            return "/stories/\(storyId)"

        // MARK: - Markets paths
        case .coinsList:
            return "/coins/list"
        case .coinsHistoryChartPreview:
            return "/coins/history_preview"
        case .tokenMarketsDetails(let requestModel):
            return "/coins/\(requestModel.tokenId)"
        case .historyChart(let requestModel):
            return "/coins/\(requestModel.tokenId)/history"
        case .tokenExchangesList(let requestModel):
            return "/coins/\(requestModel.tokenId)/exchanges"

        // MARK: - Earn paths
        case .earnYieldMarkets:
            return "/earn/markets"
        case .earnNetworks:
            return "/earn/networks"

        // MARK: - Coins paths
        case .coinsSettings:
            return "/coins/settings"

        // MARK: - Action Buttons
        case .hotCrypto:
            return "/hot_crypto"
        case .pushNotificationsEligible:
            return "/notification/push_notifications_eligible_networks"

        // MARK: Applications
        case .createUserWalletsApplication:
            return "/user-wallets/applications"
        case .updateUserWalletsApplication(let uid, _):
            return "/user-wallets/applications/\(uid)"
        case .connectUserWallets(let applicationUid, _):
            return "/user-wallets/applications/\(applicationUid)/wallets"

        // MARK: - UserWallets
        case .getUserWallets(let applicationUid):
            return "/user-wallets/wallets/by-app/\(applicationUid)"
        case .getUserWallet(let userWalletId), .updateWallet(let userWalletId, _):
            return "/user-wallets/wallets/\(userWalletId)"
        case .getNotificationPreferences(let userWalletId),
             .updateNotificationPreferences(let userWalletId, _):
            // Contract v1.3: `/api/v1/notification-preferences/{walletId}`. The `/api/v1` part comes
            // from `apiBaseUrlWithGatewaySegment` (see `baseURL`); only the relative part is set here.
            return "/notification-preferences/\(userWalletId)"

        // MARK: - Promo Code
        case .activatePromoCode:
            return "/promo-codes/activate"

        // MARK: - Accounts
        case .createWallet:
            return "/user-wallets/wallets"
        case .getUserAccounts(let userWalletId),
             .saveUserAccounts(let userWalletId, _, _):
            return "/wallets/\(userWalletId)/accounts"
        case .getArchivedUserAccounts(let userWalletId):
            return "/wallets/\(userWalletId)/accounts/archived"

        // MARK: - Address Book
        case .syncAddressBooks:
            return "/address-books/sync"
        case .updateAddressBook(let walletId, _, _):
            return "/address-books/\(walletId)"

        // MARK: - News
        case .newsList:
            return "/news"
        case .newsDetails(let requestModel):
            return "/news/\(requestModel.newsId)"
        case .newsCategories:
            return "/news/categories"
        case .trendingNews:
            return "/news/trending"

        // MARK: - Referral 2.0
        case .bindWalletsByCode:
            return "/referral/bind-wallets-by-code"
        }
    }

    var method: Moya.Method {
        switch type {
        case .rawData,
             .currencies,
             .coins,
             .quotes,
             .geo,
             .getUserWalletTokens,
             .loadReferralProgramInfo,
             .promotion,
             .yieldBoostPromotionStatus,
             .loadPromotions,
             .marketingCampaigns,
             .apiList,
             .features,
             .coinsList,
             .coinsHistoryChartPreview,
             .tokenMarketsDetails,
             .historyChart,
             .tokenExchangesList,
             .hotCrypto,
             .earnYieldMarkets,
             .earnNetworks,
             .coinsSettings,
             .story,
             .pushNotificationsEligible,
             .getUserAccounts,
             .getArchivedUserAccounts,
             .getUserWallets,
             .getUserWallet,
             .getNotificationPreferences,
             .newsList,
             .newsDetails,
             .newsCategories,
             .trendingNews:
            return .get
        case .saveUserWalletTokens,
             .saveUserWalletTokensV2,
             .saveUserAccounts,
             .connectUserWallets,
             .updateNotificationPreferences,
             .updateAddressBook:
            return .put
        case .participateInReferralProgram,
             .createAccount,
             .createUserWalletsApplication,
             .activatePromoCode,
             .createWallet,
             .bindWalletsByCode,
             .syncAddressBooks:
            return .post
        case .updateUserWalletsApplication, .updateWallet, .hidePromotion:
            return .patch
        }
    }

    var task: Task {
        switch type {
        case .rawData:
            return .requestPlain
        case .coins(let pageModel):
            return .requestParameters(pageModel)
        case .quotes(let pageModel):
            return .requestParameters(pageModel)
        case .currencies, .geo, .features, .getUserWalletTokens:
            return .requestPlain
        case .saveUserWalletTokens(_, let list),
             .saveUserWalletTokensV2(_, let list):
            return .requestJSONEncodable(list)
        case .loadReferralProgramInfo(_, let expectedAwardsLimit):
            return .requestParameters(
                parameters: [
                    "expected-awards-limit": expectedAwardsLimit,
                ],
                encoding: URLEncoding.default
            )
        case .participateInReferralProgram(let requestData):
            return .requestParameters(requestData)
        case .promotion(let request):
            return .requestParameters(request)
        case .yieldBoostPromotionStatus(let request):
            return .requestParameters(request)
        case .loadPromotions(let request):
            return .requestParameters(request)
        case .hidePromotion(let request):
            return .requestJSONEncodable(request)
        case .marketingCampaigns(let parameters):
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case .createAccount(let parameters):
            return .requestJSONEncodable(parameters)
        case .apiList:
            return .requestPlain
        case .story:
            return .requestPlain

        // MARK: - Markets tasks
        case .coinsList(let requestData):
            return .requestParameters(parameters: requestData.parameters, encoding: URLEncoding.default)
        case .coinsHistoryChartPreview(let requestData):
            return .requestParameters(parameters: requestData.parameters, encoding: URLEncoding(destination: .queryString, arrayEncoding: .noBrackets))
        case .tokenMarketsDetails(let requestModel):
            return .requestParameters(parameters: [
                "currency": requestModel.currency,
                "language": requestModel.language,
            ], encoding: URLEncoding.default)
        case .historyChart(let requestModel):
            return .requestParameters(
                parameters: [
                    "currency": requestModel.currency,
                    "interval": requestModel.interval.historyChartId,
                ],
                encoding: URLEncoding.default
            )
        case .tokenExchangesList:
            return .requestPlain

        // MARK: - Earn tasks
        case .earnYieldMarkets(let requestModel):
            return .requestParameters(parameters: requestModel.parameters, encoding: URLEncoding.default)
        case .earnNetworks(let requestModel):
            return .requestParameters(parameters: requestModel.parameters, encoding: URLEncoding.default)

        // MARK: - Coins tasks
        case .coinsSettings:
            return .requestPlain

        // MARK: - News tasks
        case .hotCrypto(let requestModel):
            return .requestParameters(parameters: ["currency": requestModel.currency], encoding: URLEncoding.default)
        case .pushNotificationsEligible:
            return .requestPlain
        case .createUserWalletsApplication(let requestModel):
            return .requestJSONEncodable(requestModel)
        case .updateUserWalletsApplication(_, let requestModel):
            return .requestJSONEncodable(requestModel)
        case .getUserWallet, .getUserWallets, .getNotificationPreferences:
            return .requestPlain
        case .updateNotificationPreferences(_, let body):
            return .requestJSONEncodable(body)
        case .updateWallet(_, let context):
            return .requestJSONEncodable(context)
        case .connectUserWallets(_, let requestModel):
            return .requestJSONEncodable(requestModel)

        // MARK: - Promo Code
        case .activatePromoCode(let requestModel):
            return .requestJSONEncodable(requestModel)

        // MARK: - Accounts
        case .createWallet(let context):
            return .requestJSONEncodable(context)
        case .getUserAccounts:
            return .requestPlain
        case .saveUserAccounts(_, _, let accounts):
            return .requestJSONEncodable(accounts)
        case .getArchivedUserAccounts:
            return .requestPlain

        // MARK: - Address Book
        case .syncAddressBooks(let request):
            return .requestJSONEncodable(request)
        case .updateAddressBook(_, _, let body):
            return .requestJSONEncodable(body)

        // MARK: - News
        case .newsList(let requestModel):
            return .requestParameters(parameters: requestModel.parameters, encoding: URLEncoding.default)
        case .newsCategories:
            return .requestPlain
        case .trendingNews(let limit, let lang):
            var parameters = [String: Any]()
            if let lang {
                parameters["lang"] = lang
            }

            if let limit {
                parameters["limit"] = limit
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.default
            )
        case .newsDetails(let requestModel):
            if let lang = requestModel.lang {
                return .requestParameters(parameters: ["lang": lang], encoding: URLEncoding.default)
            }
            return .requestPlain

        // MARK: - Referral 2.0
        case .bindWalletsByCode(let requestModel):
            return .requestJSONEncodable(requestModel)
        }
    }

    var headers: [String: String]? {
        switch type {
        case .saveUserAccounts(_, let revision, _):
            // This endpoint uses manual ETags for optimistic locking during mutations
            return [
                TangemAPIHeaders.ifMatch.rawValue: revision,
            ]
        case .updateAddressBook(_, let knownETag, _):
            // Optimistic locking: send If-Match only when we already hold an etag (the client never mints one).
            return knownETag.map { [TangemAPIHeaders.ifMatch.rawValue: $0] }
        case .rawData,
             .currencies,
             .coins,
             .quotes,
             .geo,
             .features,
             .getUserWalletTokens,
             .saveUserWalletTokens,
             .saveUserWalletTokensV2,
             .loadReferralProgramInfo,
             .participateInReferralProgram,
             .createAccount,
             .promotion,
             .yieldBoostPromotionStatus,
             .loadPromotions,
             .hidePromotion,
             .marketingCampaigns,
             .activatePromoCode,
             .story,
             .coinsList,
             .coinsHistoryChartPreview,
             .tokenMarketsDetails,
             .historyChart,
             .tokenExchangesList,
             .hotCrypto,
             .earnYieldMarkets,
             .earnNetworks,
             .coinsSettings,
             .apiList,
             .pushNotificationsEligible,
             .createUserWalletsApplication,
             .updateUserWalletsApplication,
             .getUserWallets,
             .getUserWallet,
             .updateWallet,
             .connectUserWallets,
             .getUserAccounts,
             .getArchivedUserAccounts,
             .createWallet,
             .getNotificationPreferences,
             .updateNotificationPreferences,
             .trendingNews,
             .newsList,
             .newsDetails,
             .newsCategories,
             .bindWalletsByCode,
             .syncAddressBooks:
            return nil
        }
    }
}

extension TangemApiTarget {
    enum TargetType {
        /// Used to fetch binary data (images, documents, etc.) from a given `URL`.
        case rawData(url: URL)
        case currencies
        case coins(_ requestModel: CoinsList.Request)
        case quotes(_ requestModel: QuotesDTO.Request)
        case geo
        case features
        case getUserWalletTokens(key: String)
        case saveUserWalletTokens(key: String, list: AccountsDTO.Request.UserTokens)
        case saveUserWalletTokensV2(key: String, list: AccountsDTO.Request.UserTokens)
        case loadReferralProgramInfo(userWalletId: String, expectedAwardsLimit: Int)
        case participateInReferralProgram(userInfo: ReferralParticipationRequestBody)
        case createAccount(_ parameters: BlockchainAccountCreateParameters)

        case activatePromoCode(requestModel: PromoCodeActivationDTO.Request)

        case promotion(request: BannerPromotion.Request)
        case yieldBoostPromotionStatus(request: YieldBoostPromotionDTO.Request)

        // Promotions
        case loadPromotions(request: PromotionsDTO.Load.Request)
        case hidePromotion(request: PromotionsDTO.Hide.Request)

        case marketingCampaigns(parameters: [String: Any])

        case story(_ id: String)

        // MARK: - Markets Targets

        case coinsList(_ requestModel: MarketsDTO.General.Request)
        case coinsHistoryChartPreview(_ requestModel: MarketsDTO.ChartsHistory.PreviewRequest)
        case tokenMarketsDetails(_ requestModel: MarketsDTO.Coins.Request)
        case historyChart(_ requestModel: MarketsDTO.ChartsHistory.HistoryRequest)
        case tokenExchangesList(_ requestModel: MarketsDTO.ExchangesList.Request)

        // MARK: - Earn Targets

        case earnYieldMarkets(_ requestModel: EarnDTO.List.Request)
        case earnNetworks(_ requestModel: EarnDTO.Networks.Request)

        // MARK: - Coins Targets

        case coinsSettings

        // MARK: - Action Buttons

        case hotCrypto(_ requestModel: HotCryptoDTO.Request)

        /// Configs
        case apiList

        /// Notifications
        case pushNotificationsEligible

        // Applications
        case createUserWalletsApplication(_ requestModel: ApplicationDTO.Request)
        case updateUserWalletsApplication(uid: String, requestModel: ApplicationDTO.Update.Request)
        case connectUserWallets(uid: String, requestModel: ApplicationDTO.Connect.Request)

        // User Wallets
        case getUserWallets(applicationUid: String)
        case getUserWallet(userWalletId: String)
        case updateWallet(userWalletId: String, context: Encodable)
        case createWallet(context: Encodable)

        // Notification Preferences
        case getNotificationPreferences(userWalletId: String)
        case updateNotificationPreferences(userWalletId: String, body: NotificationPreferencesDTO.Body)

        // Accounts
        case getUserAccounts(userWalletId: String)
        case saveUserAccounts(userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts)
        case getArchivedUserAccounts(userWalletId: String)

        // Address Book
        case syncAddressBooks(_ request: AddressBookDTO.SyncRequest)
        case updateAddressBook(walletId: String, knownETag: String?, body: AddressBookDTO.UpdateRequest)

        // MARK: - News Targets

        case trendingNews(limit: Int?, lang: String?)
        case newsList(_ requestModel: NewsDTO.List.Request)
        case newsDetails(_ requestModel: NewsDTO.Details.Request)
        case newsCategories
        case bindWalletsByCode(_ requestModel: ReferralDTO.Request)
    }
}

extension TangemApiTarget: CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy {
        switch type {
        case .geo, .features, .apiList, .quotes, .coinsList, .tokenMarketsDetails, .trendingNews, .newsList, .newsDetails, .newsCategories, .earnYieldMarkets, .earnNetworks, .coinsSettings, .marketingCampaigns:
            return .reloadIgnoringLocalAndRemoteCacheData
        default:
            return .useProtocolCachePolicy
        }
    }
}

extension TangemApiTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        switch type {
        case .currencies,
             .coins,
             .quotes,
             .apiList,
             .coinsList,
             .coinsHistoryChartPreview,
             .historyChart,
             .tokenMarketsDetails,
             .tokenExchangesList,
             .earnYieldMarkets,
             .earnNetworks,
             .story,
             .rawData,
             .hotCrypto,
             .createUserWalletsApplication,
             .updateUserWalletsApplication,
             .getUserWallets,
             .getUserWallet,
             .updateWallet,
             .connectUserWallets,
             .createWallet,
             .getNotificationPreferences,
             .updateNotificationPreferences,
             .newsList,
             .newsCategories,
             .newsDetails,
             .trendingNews,
             .yieldBoostPromotionStatus,
             .bindWalletsByCode:
            return false
        case .geo,
             .features,
             .getUserWalletTokens,
             .saveUserWalletTokens,
             .saveUserWalletTokensV2,
             .loadReferralProgramInfo,
             .participateInReferralProgram,
             .createAccount,
             .promotion,
             .loadPromotions,
             .hidePromotion,
             .marketingCampaigns,
             .pushNotificationsEligible,
             .getUserAccounts,
             .saveUserAccounts,
             .getArchivedUserAccounts,
             .syncAddressBooks,
             .updateAddressBook,
             .activatePromoCode,
             .coinsSettings:
            return true
        }
    }
}
