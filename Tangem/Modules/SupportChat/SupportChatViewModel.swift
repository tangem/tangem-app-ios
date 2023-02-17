//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SupportChatViewModel: ObservableObject, Identifiable {
    @Published var viewState: ViewState?

    @Injected(\.keysManager) private var keysManager: KeysManager
    private let type: SupportChatType

    init(type: SupportChatType) {
        self.type = type

        setupView()
    }

    func setupView() {
        switch type {
        case .tangem(let cardId, let dataCollector):
            viewState = .zendesk(
                ZendeskSupportChatViewModel(cardId: cardId, dataCollector: dataCollector)
            )
        case .saltPay:
            let provider = keysManager.saltPay.sprinklr

            guard var url = URL(string: provider.baseURL) else {
                viewState = .none
                return
            }

            url = url.appendingPathComponent("page")

            guard var urlComponents = URLComponents(string: url.absoluteString) else {
                viewState = .none
                return
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "appId", value: provider.appID),
                URLQueryItem(name: "device", value: "MOBILE"),
                URLQueryItem(name: "enableClose", value: "false"),
                URLQueryItem(name: "zoom", value: "false"),
            ]

            guard let url = urlComponents.url else {
                viewState = .none
                return
            }

            viewState = .webView(url)
        }
    }
}

extension SupportChatViewModel {
    enum ViewState {
        case webView(_ url: URL)
        case zendesk(_ viewModel: ZendeskSupportChatViewModel)
    }

    enum SupportChatType {
        case saltPay
        case tangem(cardId: String?, dataCollector: EmailDataCollector?)
    }
}
