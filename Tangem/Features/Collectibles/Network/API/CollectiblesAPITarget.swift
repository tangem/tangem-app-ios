//
//  CollectiblesAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct CollectiblesAPITarget: Moya.TargetType {
    let baseURL: URL
    let target: Target

    enum Target {
        case categories
        case machines(CollectiblesDTO.MachinesRequest)
        case machine(externalID: String)
        case machineNfts(externalID: String, CollectiblesDTO.MachineNftsRequest, userWalletID: String)
        case generatePurchaseTx(CollectiblesDTO.GeneratePurchaseTxRequest, userWalletID: String)
        case purchaseTxSent(CollectiblesDTO.PurchaseTxSentRequest, userWalletID: String)
        case purchaseStatus(CollectiblesDTO.PurchaseTransactionRequest, userWalletID: String)
        case openPack(CollectiblesDTO.PurchaseTransactionRequest, userWalletID: String)
        case buybackAvailability(CollectiblesDTO.BuybackAvailabilityRequest, userWalletID: String)
        case generateBuybackData(CollectiblesDTO.GenerateBuybackDataRequest, userWalletID: String)
        case buybackTxSent(CollectiblesDTO.BuybackTxSentRequest, userWalletID: String)
        case buybackStatus(CollectiblesDTO.BuybackStatusRequest, userWalletID: String)
    }

    var path: String {
        switch target {
        case .categories: "api/v1/machine/categories"
        case .machines: "api/v1/machine/machines"
        case .machine(let externalID): "api/v1/machine/\(externalID)"
        case .machineNfts(let externalID, _, _): "api/v1/machine/\(externalID)/nfts"
        case .generatePurchaseTx: "api/v1/collectible/generate-purchase-tx"
        case .purchaseTxSent: "api/v1/collectible/purchase-tx-sent"
        case .purchaseStatus: "api/v1/collectible/status"
        case .openPack: "api/v1/collectible/open-pack"
        case .buybackAvailability: "api/v1/buyback/available"
        case .generateBuybackData: "api/v1/buyback/buyback-data"
        case .buybackTxSent: "api/v1/buyback/buyback-tx-sent"
        case .buybackStatus: "api/v1/buyback/status"
        }
    }

    var method: Moya.Method {
        switch target {
        case .categories, .machines, .machine, .machineNfts, .purchaseStatus, .buybackAvailability, .buybackStatus: .get
        case .generatePurchaseTx, .purchaseTxSent, .openPack, .generateBuybackData, .buybackTxSent: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .categories, .machine: .requestPlain
        case .machines(let request): .requestParameters(request, encoding: URLEncoding.queryString)
        case .machineNfts(_, let request, _): .requestParameters(request, encoding: URLEncoding.queryString)
        case .purchaseStatus(let request, _):
            .requestParameters(request, encoding: URLEncoding(destination: .queryString, boolEncoding: .literal))
        case .generatePurchaseTx(let request, _): .requestJSONEncodable(request)
        case .purchaseTxSent(let request, _): .requestJSONEncodable(request)
        case .openPack(let request, _):
            .requestCompositeParameters(body: request, urlParameters: [Constants.includeNftWonKey: Constants.trueValue])
        case .buybackAvailability(let request, _): .requestParameters(request, encoding: URLEncoding.queryString)
        case .generateBuybackData(let request, _): .requestJSONEncodable(request)
        case .buybackTxSent(let request, _): .requestJSONEncodable(request)
        case .buybackStatus(let request, _): .requestParameters(request, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .categories, .machines, .machine: nil
        case .machineNfts(_, _, let userWalletID),
             .generatePurchaseTx(_, let userWalletID),
             .purchaseTxSent(_, let userWalletID),
             .purchaseStatus(_, let userWalletID),
             .openPack(_, let userWalletID),
             .buybackAvailability(_, let userWalletID),
             .generateBuybackData(_, let userWalletID),
             .buybackTxSent(_, let userWalletID),
             .buybackStatus(_, let userWalletID):
            ["user-id": userWalletID]
        }
    }
}

extension CollectiblesAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}

// MARK: - Constants

private extension CollectiblesAPITarget {
    enum Constants {
        static let includeNftWonKey = "includeNftWon"
        static let trueValue = "true"
    }
}
