//
//  PromotionViewModel.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import SwiftUI

final class PromotionViewModel: ObservableObject {
    @Injected(\.keysManager) var keysManager: KeysManager
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    var headers: [String: String] {
        var headers: [String: String] = [:]
        if let tangemComAuthorization = keysManager.tangemComAuthorization {
            headers["Authorization"] = "Basic \(tangemComAuthorization)"
        }
        return headers
    }

    var urlActions: [String: (String) -> Void] {
        let baseUrl = AppEnvironment.current.tangemComBaseUrl.absoluteString

        var result: [String: (String) -> Void] = [:]
        result["\(baseUrl)/\(urlPath)/code-created"] = handleCodeCreated
        result["\(baseUrl)/\(urlPath)/close"] = handleClose
        return result
    }

    var url: URL {
        var urlComponents = URLComponents(url: AppEnvironment.current.tangemComBaseUrl, resolvingAgainstBaseURL: false)!
        urlComponents.path = "/\(urlPath)/"

        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "type", value: "new-card"))
        if let promoCode = promotionService.promoCode {
            queryItems.append(URLQueryItem(name: "code", value: promoCode))
        }
        urlComponents.queryItems = queryItems

        return urlComponents.url!
    }

    private var urlPath: String {
        "promotion-test"
    }

    // MARK: - Dependencies

    private unowned let coordinator: PromotionRoutable

    init(coordinator: PromotionRoutable) {
        self.coordinator = coordinator
    }

    func handleCodeCreated(url: String) {
        guard
            let urlComponents = URLComponents(string: url),
            let queryItem = urlComponents.queryItems?.first(where: { $0.name == "code" }),
            let code = queryItem.value
        else {
            return
        }

        promotionService.setPromoCode(code)
    }

    func handleClose(url: String) {
        coordinator.closeModule()
    }
}
