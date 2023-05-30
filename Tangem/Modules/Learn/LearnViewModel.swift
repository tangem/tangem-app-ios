//
//  LearnViewModel.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import SwiftUI

final class LearnViewModel: ObservableObject {
    @Injected(\.keysManager) var keysManager: KeysManager

    // MARK: - ViewState

    var headers: [String: String] {
        var result: [String: String] = [:]
        if let tangemComAuthorization = keysManager.tangemComAuthorization {
            result["Authorization"] = "Basic \(tangemComAuthorization)"
        }
        return result
    }

    var urlActions: [String: (String) -> Void] {
        let baseUrl = AppEnvironment.current.tangemComBaseUrl.absoluteString

        var result: [String: (String) -> Void] = [:]
        result["\(baseUrl)/promotion-program/code-created"] = handleCodeCreated
        result["\(baseUrl)/promotion-program/close"] = handleClose
        return result
    }

    var url: URL {
        var urlComponents = URLComponents(url: AppEnvironment.current.tangemComBaseUrl, resolvingAgainstBaseURL: false)!
        urlComponents.path = "/promotion-program/"

        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "type", value: "new-card"))
        urlComponents.queryItems = queryItems

        return urlComponents.url!
    }

    // MARK: - Dependencies

    private unowned let coordinator: LearnRoutable

    init(coordinator: LearnRoutable) {
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

        print(url)
        print(code)
    }

    func handleClose(url: String) {
        coordinator.closeModule()
    }
}
