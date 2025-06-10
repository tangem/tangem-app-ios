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
    var timeoutSettings: WebViewTimeoutSettings?
}
