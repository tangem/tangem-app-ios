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
        case .getUserWalletTokens(let key),
             .saveUserWalletTokensLegacy(let key, _):
            return "/user-tokens/\(key)"
        case .saveUserWalletTokens(let key, _):
            return "/wallets/\(key)/tokens"
        case .loadReferralProgramInfo(let userWalletId, _):
            return "/referral/\(userWalletId)"
        case .participateInReferralProgram:
            return "/referral"
        case .promotion:
            return "/promotion"
        case .validateNewUserPromotionEligibility:
            return "/promotion/code/validate"
        case .validateOldUserPromotionEligibility:
            return "/promotion/validate"
        case .awardNewUser:
            return "/promotion/code/award"
        case .awardOldUser:
            return "/promotion/award"
        case .resetAward:
            return "/private/manual-check/promotion-award"
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

        // MARK: - Action Buttons
        case .hotCrypto:
            return "/hot_crypto"

        // MARK: SeedNotify
        case .seedNotifyGetStatus(let userWalletId), .seedNotifySetStatus(let userWalletId, _):
            return "/seedphrase-notification/\(userWalletId)"
        case .seedNotifyGetStatusConfirmed(let userWalletId), .seedNotifySetStatusConfirmed(let userWalletId, _):
            return "/seedphrase-notification/\(userWalletId)/confirmed"
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

        // MARK: - News
        case .newsList:
            return "/news"
        case .newsCategories:
            return "/news/categories"
        case .trendingNews:
            return "/news/trending"
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
             .apiList,
             .features,
             .coinsList,
             .coinsHistoryChartPreview,
             .tokenMarketsDetails,
             .historyChart,
             .tokenExchangesList,
             .hotCrypto,
             .seedNotifyGetStatus,
             .seedNotifyGetStatusConfirmed,
             .story,
             .pushNotificationsEligible,
             .getUserAccounts,
             .getArchivedUserAccounts,
             .getUserWallets,
             .getUserWallet,
             .newsList,
             .newsCategories,
             .trendingNews:
            return .get
        case .saveUserWalletTokensLegacy,
             .saveUserWalletTokens,
             .saveUserAccounts,
             .seedNotifySetStatus,
             .seedNotifySetStatusConfirmed,
             .connectUserWallets:
            return .put
        case .participateInReferralProgram,
             .validateNewUserPromotionEligibility,
             .validateOldUserPromotionEligibility,
             .awardNewUser,
             .awardOldUser,
             .createAccount,
             .createUserWalletsApplication,
             .activatePromoCode,
             .createWallet:
            return .post
        case .resetAward:
            return .delete
        case .updateUserWalletsApplication, .updateWallet:
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
        case .saveUserWalletTokensLegacy(_, let list):
            return .requestJSONEncodable(list)
        case .saveUserWalletTokens(_, let list):
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
        case .validateNewUserPromotionEligibility(let walletId, let code):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "code": code,
            ], encoding: JSONEncoding.default)
        case .validateOldUserPromotionEligibility(let walletId, let programName):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "programName": programName,
            ], encoding: JSONEncoding.default)
        case .awardNewUser(let walletId, let address, let code):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "address": address,
                "code": code,
            ], encoding: JSONEncoding.default)
        case .awardOldUser(let walletId, let address, let programName):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "address": address,
                "programName": programName,
            ], encoding: JSONEncoding.default)
        case .resetAward(let cardId):
            return .requestParameters(parameters: [
                "cardId": cardId,
            ], encoding: URLEncoding.default)
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
        case .seedNotifySetStatus(_, let status), .seedNotifySetStatusConfirmed(_, let status):
            let requestModel = SeedNotifyDTO(status: status)
            return .requestParameters(requestModel, encoding: URLEncoding.default)
        case .tokenExchangesList, .seedNotifyGetStatus, .seedNotifyGetStatusConfirmed:
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
        case .getUserWallet, .getUserWallets:
            return .requestPlain
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
        }
    }

    var headers: [String: String]? {
        switch type {
        case .saveUserAccounts(_, let revision, _):
            // This endpoint uses manual ETags for optimistic locking during mutations
            return [
                TangemAPIHeaders.ifMatch.rawValue: revision,
            ]
        case .rawData,
             .currencies,
             .coins,
             .quotes,
             .geo,
             .features,
             .getUserWalletTokens,
             .saveUserWalletTokensLegacy,
             .saveUserWalletTokens,
             .loadReferralProgramInfo,
             .participateInReferralProgram,
             .createAccount,
             .promotion,
             .validateNewUserPromotionEligibility,
             .validateOldUserPromotionEligibility,
             .awardNewUser,
             .awardOldUser,
             .resetAward,
             .activatePromoCode,
             .story,
             .coinsList,
             .coinsHistoryChartPreview,
             .tokenMarketsDetails,
             .historyChart,
             .tokenExchangesList,
             .hotCrypto,
             .apiList,
             .seedNotifyGetStatus,
             .seedNotifySetStatus,
             .seedNotifyGetStatusConfirmed,
             .seedNotifySetStatusConfirmed,
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
             .trendingNews,
             .newsList,
             .newsCategories:
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
        @available(iOS, deprecated: 100000.0, message: "Superseded by '.saveUserWalletTokens(key:list:)', will be removed in the future ([REDACTED_INFO])")
        case saveUserWalletTokensLegacy(key: String, list: UserTokenList)
        case saveUserWalletTokens(key: String, list: AccountsDTO.Request.UserTokens)
        case loadReferralProgramInfo(userWalletId: String, expectedAwardsLimit: Int)
        case participateInReferralProgram(userInfo: ReferralParticipationRequestBody)
        case createAccount(_ parameters: BlockchainAccountCreateParameters)

        // Promotion
        case promotion(request: ExpressPromotion.Request)
        case validateNewUserPromotionEligibility(walletId: String, code: String)
        case validateOldUserPromotionEligibility(walletId: String, programName: String)
        case awardNewUser(walletId: String, address: String, code: String)
        case awardOldUser(walletId: String, address: String, programName: String)
        case resetAward(cardId: String)
        case activatePromoCode(requestModel: PromoCodeActivationDTO.Request)

        case story(_ id: String)

        // MARK: - Markets Targets

        case coinsList(_ requestModel: MarketsDTO.General.Request)
        case coinsHistoryChartPreview(_ requestModel: MarketsDTO.ChartsHistory.PreviewRequest)
        case tokenMarketsDetails(_ requestModel: MarketsDTO.Coins.Request)
        case historyChart(_ requestModel: MarketsDTO.ChartsHistory.HistoryRequest)
        case tokenExchangesList(_ requestModel: MarketsDTO.ExchangesList.Request)

        // MARK: - Action Buttons

        case hotCrypto(_ requestModel: HotCryptoDTO.Request)

        /// Configs
        case apiList

        // Seed notification
        case seedNotifyGetStatus(userWalletId: String)
        case seedNotifySetStatus(userWalletId: String, status: SeedNotifyStatus)
        case seedNotifyGetStatusConfirmed(userWalletId: String)
        case seedNotifySetStatusConfirmed(userWalletId: String, status: SeedNotifyStatus)

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

        // Accounts
        case getUserAccounts(userWalletId: String)
        case saveUserAccounts(userWalletId: String, revision: String, accounts: AccountsDTO.Request.Accounts)
        case getArchivedUserAccounts(userWalletId: String)

        // MARK: - News

        case trendingNews(limit: Int?, lang: String?)
        case newsList(_ requestModel: NewsDTO.List.Request)
        case newsCategories
    }
}

extension TangemApiTarget: CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy {
        switch type {
        case .geo, .features, .apiList, .quotes, .coinsList, .tokenMarketsDetails, .newsList, .newsCategories:
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
             .newsList,
             .newsCategories,
             .trendingNews:
            return false
        case .geo,
             .features,
             .getUserWalletTokens,
             .saveUserWalletTokensLegacy,
             .saveUserWalletTokens,
             .loadReferralProgramInfo,
             .participateInReferralProgram,
             .createAccount,
             .promotion,
             .validateNewUserPromotionEligibility,
             .validateOldUserPromotionEligibility,
             .awardNewUser,
             .awardOldUser,
             .resetAward,
             .seedNotifyGetStatus,
             .seedNotifySetStatus,
             .seedNotifyGetStatusConfirmed,
             .seedNotifySetStatusConfirmed,
             .pushNotificationsEligible,
             .getUserAccounts,
             .saveUserAccounts,
             .getArchivedUserAccounts,
             .activatePromoCode:
            return true
        }
    }
}
