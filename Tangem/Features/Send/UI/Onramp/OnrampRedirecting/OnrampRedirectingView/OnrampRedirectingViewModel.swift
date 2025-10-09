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

    private var colorScheme: ColorScheme = .light

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
        let theme: OnrampRedirectSettings.Theme = switch colorScheme {
        case .light: .light
        case .dark: .dark
        @unknown default: .light
        }

        do {
            try await interactor.loadRedirectData(theme: theme)
        } catch {
            await runOnMain {
                alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription) { [weak self] in
                    self?.coordinator?.dismissOnrampRedirecting()
                }
            }
        }
    }

    func update(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
}
