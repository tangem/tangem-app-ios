//
//  TangemPayOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemPay

enum TangemPayOnboardingSource {
    case deeplink(String)
    case other
}

final class TangemPayOnboardingViewModel: ObservableObject {
    @Injected(\.tangemPayAvailabilityRepository)
    private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    let closeOfferScreen: @MainActor () -> Void
    @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?

    private let source: TangemPayOnboardingSource
    private let availabilityService: TangemPayAvailabilityService
    private weak var coordinator: TangemPayOnboardingRoutable?

    init(
        source: TangemPayOnboardingSource,
        coordinator: TangemPayOnboardingRoutable?,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.source = source
        self.coordinator = coordinator
        self.closeOfferScreen = closeOfferScreen

        availabilityService = TangemPayAvailabilityServiceBuilder().build()
    }

    func onAppear() {
        Task {
            await prepareTangemPayOffer()
        }
    }

    private func prepareTangemPayOffer() async {
        let minimumLoaderShowingTimeTask = Task {
            try await Task.sleep(nanoseconds: 800_000_000)
        }

        do {
            switch source {
            case .deeplink(let deeplink):
                guard tangemPayAvailabilityRepository.isUserWalletModelsAvailable else {
                    throw TangemPayOnboardingError.noAvailableWallets
                }

                try await validateDeeplink(deeplinkString: deeplink)
            case .other:
                break
            }
            try? await minimumLoaderShowingTimeTask.value

            await MainActor.run {
                tangemPayOfferViewModel = TangemPayOfferViewModel(
                    closeOfferScreen: closeOfferScreen,
                    coordinator: coordinator
                )
            }
        } catch {
            try? await minimumLoaderShowingTimeTask.value
            await closeOfferScreen()
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
        case noAvailableWallets
    }
}

extension TangemPayOnboardingViewModel: Identifiable {
    var id: String {
        "\(source)"
    }
}
