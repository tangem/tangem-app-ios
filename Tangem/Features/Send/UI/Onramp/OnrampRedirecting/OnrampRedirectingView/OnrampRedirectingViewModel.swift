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
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class OnrampRedirectingViewModel: ObservableObject, Identifiable {
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
    private let theme: OnrampRedirectSettings.Theme

    init(
        tokenItem: TokenItem,
        interactor: OnrampRedirectingInteractor,
        coordinator: OnrampRedirectingRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.coordinator = coordinator
        theme = Self.resolveCurrentTheme()

        loadRedirectData()
    }

    func loadRedirectData() {
        runTask(in: self) { input in
            do {
                try await input.interactor.loadRedirectData(theme: input.theme)
            } catch {
                await runOnMain { [weak input] in
                    input?.alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription) { [weak input] in
                        input?.coordinator?.dismissOnrampRedirecting()
                    }
                }
            }
        }
    }

    private static func resolveCurrentTheme() -> OnrampRedirectSettings.Theme {
        let theme: OnrampRedirectSettings.Theme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        return theme
    }
}
