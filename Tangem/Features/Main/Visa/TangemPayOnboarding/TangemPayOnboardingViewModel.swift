//
//  TangemPayOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

final class TangemPayOnboardingViewModel: ObservableObject {
    let closeOfferScreen: @MainActor @Sendable () -> Void
    @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?

    private let deeplinkString: String
    private let userWalletModel: UserWalletModel
    private let availabilityService: TangemPayAvailabilityService

    init(
        deeplinkString: String,
        userWalletModel: UserWalletModel,
        closeOfferScreen: @escaping @MainActor @Sendable () -> Void
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
            let tangemPayAuthorizer = try await makeTangemPayAuthorizer()

            try? await minimumLoaderShowingTimeTask.value

            await MainActor.run {
                tangemPayOfferViewModel = TangemPayOfferViewModel(
                    tangemPayAuthorizer: tangemPayAuthorizer,
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

    private func makeTangemPayAuthorizer() async throws -> TangemPayAuthorizer {
        if let walletModel = userWalletModel.visaWalletModel {
            return TangemPayAuthorizer(walletModel: walletModel)
        }

        let visaBlockchainNetwork = BlockchainNetwork(
            VisaUtilities.visaBlockchain,
            derivationPath: VisaUtilities.visaDefaultDerivationPath
        )
        _ = try await userWalletModel.userTokensManager.add(.blockchain(visaBlockchainNetwork))

        if let walletModel = userWalletModel.visaWalletModel {
            return TangemPayAuthorizer(walletModel: walletModel)
        }

        throw TangemPayOnboardingError.unableToCreateRequiredWalletModel
    }
}

private extension TangemPayOnboardingViewModel {
    enum TangemPayOnboardingError: Error {
        case invalidDeeplink
        case unableToCreateRequiredWalletModel
    }
}

extension UserWalletModel {
    var visaWalletModel: (any WalletModel)? {
        walletModelsManager.walletModels
            .first { $0.tokenItem.blockchain == VisaUtilities.visaBlockchain }
    }
}
