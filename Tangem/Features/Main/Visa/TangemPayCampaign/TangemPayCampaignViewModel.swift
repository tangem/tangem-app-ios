//
//  TangemPayCampaignViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI
import TangemVisa
import struct TangemUIUtils.AlertBinder

protocol TangemPayCampaignRoutable: AnyObject {
    func openWalletSelector(
        from userWalletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    )
    func openLegalDocument(url: URL)
    func openCardsLimitSheet(canUpgradePlan: Bool, userWalletModel: UserWalletModel)
    func closeCampaign()
    func finishCampaign(userWalletModel: UserWalletModel)
}

final class TangemPayCampaignViewModel: ObservableObject {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Published private(set) var state: ViewState = .loading
    @Published private(set) var isCTALoading = false
    @Published var alert: AlertBinder?

    /// A fresh install opens straight onto the Not authorised landing, so there is nothing behind it.
    var showsCloseButton: Bool {
        guard case .landing(let landing) = state else { return true }
        return landing.mode == .noPay
    }

    var showsLegalCaption: Bool {
        guard case .landing(let landing) = state else { return false }
        return landing.mode == .noWallet
    }

    /// The icon promises a card tap, so it belongs only to a single wallet that actually needs NFC —
    /// the same rule `CommonTangemIconProvider` applies on the regular Tangem Pay offer.
    var showsCTAIcon: Bool {
        guard case .landing(let landing) = state, landing.mode == .noPay else { return false }

        let userWalletModels = eligibleUserWalletModels
        guard userWalletModels.count == 1, let userWalletModel = userWalletModels.first else { return false }

        return userWalletModel.config.hasFeature(.nfcInteraction)
    }

    var issueCardInfoRows: [TangemPayOrderCardInfoRow] {
        guard case .issueCard(let issueCard) = state else { return [] }

        return [
            TangemPayOrderCardInfoRow(
                id: .issueFee,
                title: Localization.tangempayOrderTypeIssueFee,
                value: issueCard.fee.map(formatted) ?? Constants.unknownValue
            ),
            TangemPayOrderCardInfoRow(
                id: .issueTime,
                title: Localization.tangempayCampaignIssueTime,
                value: Localization.tangempayOrderTypeDeliveryTimeInstant
            ),
        ]
    }

    private let campaignKey: String
    private let campaignService = TangemPayCampaignService()
    private let hotWalletCreator = TangemPayCampaignHotWalletCreator()
    private let fiatAmountFormatter = TangemPayFiatAmountFormatter()
    private weak var coordinator: TangemPayCampaignRoutable?

    private var didResolve = false
    private var createdUserWalletModel: UserWalletModel?
    private var ctaTask: Task<Void, Never>?
    private var resolveTask: Task<Void, Never>?

    init(campaignKey: String, coordinator: TangemPayCampaignRoutable?) {
        self.campaignKey = campaignKey
        self.coordinator = coordinator
    }

    func onAppear() {
        guard !didResolve else { return }

        didResolve = true
        resolve()
    }

    func retry() {
        resolve()
    }

    func close() {
        ctaTask?.cancel()
        resolveTask?.cancel()
        campaignService.clearPending()

        // The Payment account cover was dismissed to present the campaign, so closing has to restore it.
        if case .issueCard(let issueCard) = state {
            coordinator?.finishCampaign(userWalletModel: issueCard.userWalletModel)
        } else {
            coordinator?.closeCampaign()
        }
    }

    func openLegalDocument(url: URL) {
        coordinator?.openLegalDocument(url: url)
    }

    func getCard() {
        guard case .landing(let landing) = state, !isCTALoading else { return }

        switch landing.mode {
        case .noWallet:
            createWalletThenOnboard()
        case .noPay:
            selectWalletThenOnboard()
        }
    }

    func issueCampaignCard() {
        guard case .issueCard(let issueCard) = state, !isCTALoading else { return }

        isCTALoading = true
        ctaTask = runTask(in: self) { @MainActor viewModel in
            do {
                _ = try await issueCard.tangemPayAccount.issueCampaignCard(deeplinkValue: viewModel.campaignKey)
                viewModel.isCTALoading = false
                viewModel.campaignService.clearPending()
                viewModel.coordinator?.finishCampaign(userWalletModel: issueCard.userWalletModel)
            } catch {
                await viewModel.handleIssueFailure(error, issueCard: issueCard)
            }
        }
    }
}

// MARK: - Resolution

private extension TangemPayCampaignViewModel {
    func resolve() {
        resolveTask?.cancel()
        state = .loading

        resolveTask = runTask(in: self) { @MainActor viewModel in
            let resolution: TangemPayCampaignResolution
            do {
                let resolver = TangemPayCampaignResolver(campaignKey: viewModel.campaignKey)
                resolution = try await resolver.resolve()
            } catch {
                guard !Task.isCancelled else { return }

                VisaLogger.error("Failed to resolve Tangem Pay campaign", error: error)
                viewModel.state = .error
                return
            }

            guard !Task.isCancelled else { return }

            viewModel.apply(resolution)
        }
    }

    func apply(_ resolution: TangemPayCampaignResolution) {
        switch resolution {
        case .landing(let landing):
            state = .landing(landing)

            switch landing.mode {
            case .noWallet:
                Analytics.log(.visaOnboardingCobrandDesignOnboardingNewHotWallet, analyticsSystems: .all)
            case .noPay:
                Analytics.log(.visaOnboardingCobrandDesignOnboardingNotInPay, analyticsSystems: .all)
            }

        case .issueCard(let issueCard):
            state = .issueCard(issueCard)
            Analytics.log(.visaOnboardingCobrandDesignOnboardingExistPay, analyticsSystems: .all)

        case .unavailable:
            showUnavailableAlert()
        }
    }
}

// MARK: - Get card

private extension TangemPayCampaignViewModel {
    func createWalletThenOnboard() {
        if let restrictionAlert = hotWalletCreator.restrictionAlert {
            alert = restrictionAlert
            return
        }

        isCTALoading = true
        ctaTask = runTask(in: self) { @MainActor viewModel in
            let userWalletModel: UserWalletModel
            do {
                userWalletModel = try await viewModel.createOrReuseWallet()
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                viewModel.isCTALoading = false
                viewModel.state = .error
                return
            }

            do {
                try await viewModel.onboard(userWalletModel)
            } catch let error as TangemPayCampaignOfferError {
                viewModel.handleCampaignOfferFailure(error)
                return
            } catch {
                viewModel.isCTALoading = false
                viewModel.state = .error
                return
            }

            viewModel.isCTALoading = false
            viewModel.coordinator?.finishCampaign(userWalletModel: userWalletModel)
        }
    }

    func selectWalletThenOnboard() {
        let userWalletModels = eligibleUserWalletModels

        guard let firstUserWalletModel = userWalletModels.first else {
            showUnavailableAlert()
            return
        }

        guard userWalletModels.count > 1 else {
            onboardExistingWallet(firstUserWalletModel)
            return
        }

        coordinator?.openWalletSelector(from: userWalletModels) { [weak self] userWalletModel in
            self?.onboardExistingWallet(userWalletModel)
        }
    }

    /// KYC leaves the user on the app home while the campaign card is still being issued, so the campaign
    /// screen only has to close behind it.
    func onboardExistingWallet(_ userWalletModel: UserWalletModel) {
        isCTALoading = true
        ctaTask = runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.onboard(userWalletModel)
            } catch let error as TangemPayCampaignOfferError {
                viewModel.handleCampaignOfferFailure(error)
                return
            } catch {
                viewModel.isCTALoading = false
                viewModel.state = .error
                return
            }

            viewModel.isCTALoading = false
            viewModel.close()
        }
    }

    /// `createWallet` has already added the wallet to the repository, so a retry after a cancelled
    /// authorization must not make another one.
    func createOrReuseWallet() async throws -> UserWalletModel {
        if let createdUserWalletModel {
            return createdUserWalletModel
        }

        let userWalletModel = try await hotWalletCreator.createWallet()
        createdUserWalletModel = userWalletModel
        return userWalletModel
    }

    func onboard(_ userWalletModel: UserWalletModel) async throws(TangemPayCampaignOfferError) {
        try await userWalletModel.accountModelsManager.acceptTangemPayCampaignOffer(
            authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor,
            campaignKey: campaignKey
        )
        campaignService.clearPending()
    }

    func handleCampaignOfferFailure(_ error: TangemPayCampaignOfferError) {
        isCTALoading = false

        switch error {
        case .authorization(let authorizationError):
            guard !authorizationError.isUserCancelled else { return }

            alert = AlertBinder(
                title: Localization.commonError,
                message: authorizationError.serverErrorStatusCode == nil
                    ? Localization.commonUnknownError
                    : Localization.commonServerUnavailable
            )

        case .accountAlreadyExists:
            resolve()

        case .order(.offerUnavailable):
            showUnavailableAlert()

        case .order(.missingCustomerWalletAddress), .order(.api), .unexpectedState:
            state = .error
        }
    }
}

// MARK: - Issue failures

private extension TangemPayCampaignViewModel {
    @MainActor
    func handleIssueFailure(_ error: Error, issueCard: TangemPayCampaignIssueCard) async {
        VisaLogger.error("Failed to issue Tangem Pay campaign card", error: error)

        if case TangemPayAccountError.missingCardIssueOffer = error {
            showUnavailableAlert()
            return
        }

        // The CTA stays loading across the lookup, or a second tap places another order while this one
        // is still deciding which limit sheet to show.
        if (error as? TangemPayAPIServiceError)?.apiErrorCode == TangemPayAPIError.Code.cardIssueOfferNotAvailable {
            let canUpgradePlan = await isTariffPlanUpgradeAvailable(on: issueCard.tangemPayAccount)
            isCTALoading = false
            coordinator?.openCardsLimitSheet(
                canUpgradePlan: canUpgradePlan,
                userWalletModel: issueCard.userWalletModel
            )
            return
        }

        isCTALoading = false

        let snackbar = TangemSnackbar(title: Localization.commonUnknownError)
            .icon(DesignSystem.Icons.Error.regular20)
            .iconColor(DesignSystem.Color.iconStatusError)
        Toast(view: snackbar).present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    func isTariffPlanUpgradeAvailable(on tangemPayAccount: TangemPayAccount) async -> Bool {
        do {
            let transitions = try await tangemPayAccount.getTariffPlanTransitions()
            return transitions.contains { $0.type == .upgrade }
        } catch {
            VisaLogger.error("Failed to load tariff plan transitions", error: error)
            return false
        }
    }
}

// MARK: - Helpers

private extension TangemPayCampaignViewModel {
    /// The campaign is open to existing Tangem Pay customers, so the offer availability — which drops
    /// every wallet already known to the issuer — must not narrow the choice here.
    var eligibleUserWalletModels: [UserWalletModel] {
        userWalletRepository.models.filter(\.supportsTangemPay)
    }

    func showUnavailableAlert() {
        isCTALoading = false
        alert = AlertBinder(
            alert: Alert(
                title: Text(Localization.tangempayCampaignUnavailableTitle),
                message: Text(Localization.tangempayCampaignUnavailableDescription),
                dismissButton: .default(Text(Localization.commonOk)) { [weak self] in
                    self?.close()
                }
            )
        )
    }

    func formatted(_ fee: TangemPayCustomerOffer.Fee) -> String {
        fiatAmountFormatter.format(fee.amount, currencyCode: fee.currency, hidesFractionForWholeAmounts: true)
    }
}

// MARK: - ViewState

extension TangemPayCampaignViewModel {
    enum ViewState {
        case loading
        case error
        case landing(TangemPayCampaignLanding)
        case issueCard(TangemPayCampaignIssueCard)
    }
}

private extension TangemPayCampaignViewModel {
    enum Constants {
        static let unknownValue = AppConstants.emDashSign
        static let toastTopPadding: CGFloat = 12
    }
}
