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
    static func sprinklSupportChat(appID: String) -> WebViewContainerViewModel {
        let baseURL = "https://live-chat-static.sprinklr.com/chat/page/floLbo9_o/index.html?"
        var url = URLComponents(string: baseURL)!
        url.queryItems = [
            URLQueryItem(name: "appId", value: appID), // "60c1d169c96beb5bf5a326f3_app_950954"
            URLQueryItem(name: "device", value: "MOBILE"),
            URLQueryItem(name: "enableClose", value: "true"),
            URLQueryItem(name: "zoom", value: "false"),
        ]

        return WebViewContainerViewModel(
            url: url.url,
            title: Localization.chatButtonTitle,
            addLoadingIndicator: false,
            withCloseButton: true,
            withNavigationBar: true,
            urlActions: [:]
        )
    }
}
