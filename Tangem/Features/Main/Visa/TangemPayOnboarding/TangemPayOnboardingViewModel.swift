//
//  TangemPayOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

final class TangemPayOnboardingViewModel: ObservableObject {
    let closeOfferScreen: @MainActor () -> Void
    @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?

    private let deeplinkString: String
    private let userWalletModel: UserWalletModel
    private let availabilityService: TangemPayAvailabilityService

    init(
        deeplinkString: String,
        userWalletModel: UserWalletModel,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.deeplinkString = deeplinkString
        self.userWalletModel = userWalletModel
        self.closeOfferScreen = closeOfferScreen

        availabilityService = VisaAPIServiceBuilder().buildTangemPayAvailabilityService()
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
            try await validateDeeplink()
            try? await minimumLoaderShowingTimeTask.value

            await MainActor.run {
                tangemPayOfferViewModel = TangemPayOfferViewModel(
                    userWalletModel: userWalletModel,
                    closeOfferScreen: closeOfferScreen
                )
            }
        } catch {
            try? await minimumLoaderShowingTimeTask.value
            await closeOfferScreen()
        }
    }

    private func validateDeeplink() async throws {
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
    }
}
