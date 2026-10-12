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
        case generateTx(CollectiblesDTO.GenerateTxRequest, userWalletID: String)
        case submitTx(CollectiblesDTO.SubmitTxRequest, userWalletID: String)
    }

    var path: String {
        switch target {
        case .categories: "api/v1/machine/categories"
        case .machines: "api/v1/machine/machines"
        case .machine(let externalID): "api/v1/machine/\(externalID)"
        case .generateTx: "api/v1/collectible/generateTx"
        case .submitTx: "api/v1/collectible/submitTx"
        }
    }

    var method: Moya.Method {
        switch target {
        case .categories, .machines, .machine: .get
        case .generateTx, .submitTx: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .categories, .machine: .requestPlain
        case .machines(let request): .requestParameters(request, encoding: URLEncoding.queryString)
        case .generateTx(let request, _): .requestJSONEncodable(request)
        case .submitTx(let request, _): .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .categories, .machines, .machine: nil
        case .generateTx(_, let userWalletID), .submitTx(_, let userWalletID): ["user-id": userWalletID]
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
