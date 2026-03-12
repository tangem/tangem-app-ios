//
//  TangemPayOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

enum TangemPayOnboardingSource {
    case deeplink(String)
    case other
}

final class TangemPayOnboardingViewModel: ObservableObject {
    let closeOfferScreen: @MainActor () -> Void
    @MainActor @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?

    private let source: TangemPayOnboardingSource
    private let availableSelection: TangemPayWalletSelectionType
    private let availabilityService: PaymentAccountAvailabilityService
    private weak var coordinator: TangemPayOnboardingRoutable?

    init(
        source: TangemPayOnboardingSource,
        availableSelection: TangemPayWalletSelectionType,
        coordinator: TangemPayOnboardingRoutable?,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.source = source
        self.availableSelection = availableSelection
        self.coordinator = coordinator
        self.closeOfferScreen = closeOfferScreen

        availabilityService = PaymentAccountAvailabilityServiceBuilder().build()
    }

    @MainActor
    func onAppear() {
        switch source {
        case .other:
            tangemPayOfferViewModel = TangemPayOfferViewModel(
                walletSelectionType: availableSelection,
                closeOfferScreen: closeOfferScreen,
                coordinator: coordinator
            )

        case .deeplink(let deeplinkString):
            let minimumLoaderShowingTimeTask = Task {
                try await Task.sleep(nanoseconds: 800_000_000)
            }

            runTask { [self] in
                do {
                    try await validateDeeplink(deeplinkString: deeplinkString)
                    try? await minimumLoaderShowingTimeTask.value

                    tangemPayOfferViewModel = TangemPayOfferViewModel(
                        walletSelectionType: availableSelection,
                        closeOfferScreen: closeOfferScreen,
                        coordinator: coordinator
                    )
                } catch {
                    try? await minimumLoaderShowingTimeTask.value
                    closeOfferScreen()
                }
            }
        }
    }

    private func validateDeeplink(deeplinkString: String) async throws {
        let validationResponse = try await availabilityService.validateDeeplink(deeplinkString: deeplinkString)
        switch validationResponse.status {
        case .valid:
            break
        case .invalid:
            throw TangemPayOnboardingError.invalidDeeplink
        }
    }
}

private extension TangemPayOnboardingViewModel {
    enum TangemPayOnboardingError: Error {
        case invalidDeeplink
        case offerIsNotAvailable
        case tangemPayIsNotAvailable
    }
}

extension TangemPayOnboardingViewModel: Identifiable {
    var id: String {
        "\(source)"
    }
}
