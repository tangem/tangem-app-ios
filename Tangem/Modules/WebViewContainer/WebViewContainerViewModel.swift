//
//  WebViewContainerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WebViewContainerViewModel: Identifiable {
    let id = UUID()
    var url: URL?
    var title: String
    var addLoadingIndicator = false
    var withCloseButton = false
    var withNavigationBar: Bool = true
    var urlActions: [String: (String) -> Void] = [:]
    var contentInset: UIEdgeInsets?
}

extension WebViewContainerViewModel {
    static func sprinklSupportChat(provider: SprinklrProvider) -> WebViewContainerViewModel {
        var url = URL(string: provider.baseURL)!
        url = url.appendingPathComponent("page")

        var urlComponents = URLComponents(string: url.absoluteString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "appId", value: provider.appID),
            URLQueryItem(name: "device", value: "MOBILE"),
            URLQueryItem(name: "enableClose", value: "true"),
            URLQueryItem(name: "zoom", value: "false"),
        ]

        return WebViewContainerViewModel(
            url: urlComponents?.url,
            title: Localization.chatButtonTitle,
            addLoadingIndicator: false,
            withCloseButton: true,
            withNavigationBar: true,
            urlActions: [:]
        )
    }
}
