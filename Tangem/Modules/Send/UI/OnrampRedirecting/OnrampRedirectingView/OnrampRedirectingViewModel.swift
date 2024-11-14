//
//  OnrampRedirectingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class OnrampRedirectingViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String {
        "\(Localization.commonBuy) \(tokenItem.name)"
    }

    var providerImageURL: URL? {
        interactor.onrampProvider?.provider.imageURL
    }

    var providerName: String {
        interactor.onrampProvider?.provider.name ?? Localization.expressProvider
    }

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampRedirectingInteractor
    private weak var coordinator: OnrampRedirectingRoutable?

    init(
        tokenItem: TokenItem,
        interactor: OnrampRedirectingInteractor,
        coordinator: OnrampRedirectingRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.coordinator = coordinator
    }

    func loadRedirectData() async {
        do {
            try await interactor.loadRedirectData()
            try await Task.sleep(seconds: 10)

            await runOnMain {
                coordinator?.dismissOnrampRedirecting()
            }
        } catch {
            await runOnMain {
                // [REDACTED_TODO_COMMENT]
                alert = error.alertBinder
            }
        }
    }
}
