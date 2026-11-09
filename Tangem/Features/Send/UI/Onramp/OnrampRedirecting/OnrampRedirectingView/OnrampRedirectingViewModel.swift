//
//  OnrampRedirectingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Kingfisher
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

    var providerName: String {
        interactor.onrampProvider?.provider.name ?? Localization.expressProvider
    }

    @Published var alert: AlertBinder?
    @Published private(set) var providerLogo: ProviderLogo = .loading

    private var providerImageURL: URL? {
        interactor.onrampProvider?.provider.imageURL
    }

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
                alert = AlertBuilder.makeOkErrorAlert(message: error.localizedExpressMessage) { [weak self] in
                    self?.coordinator?.dismissOnrampRedirecting()
                }
            }
        }
    }

    func loadProviderLogo() async {
        guard let providerImageURL else {
            await runOnMain { providerLogo = .unavailable }
            return
        }

        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: providerImageURL)
            await runOnMain { providerLogo = .loaded(Image(uiImage: result.image)) }
        } catch {
            await runOnMain { providerLogo = .unavailable }
        }
    }

    func update(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
}

// MARK: - ProviderLogo

extension OnrampRedirectingViewModel {
    enum ProviderLogo {
        case loading
        case loaded(Image)
        case unavailable
    }
}
