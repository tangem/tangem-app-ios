//
//  CampaignViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI
import TangemFoundation
import TangemLocalization

final class CampaignViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var viewState: ViewState = .idle
    @Published var tokenSelectorViewModel: CampaignTokenSelectorViewModel?
    @Published private(set) var selectedTokenRowViewModel: TokenSelectorItemViewModel?
    @Published private(set) var isEnrolling = false

    private let campaignId: String

    var selectedTokenNetworkName: String {
        selectedToken?.tokenItem.networkName ?? ""
    }

    var selectedAccountViewData: SelectedAccountViewData? {
        guard hasMultipleAccounts, let account = selectedToken?.kind.account else {
            return nil
        }

        return SelectedAccountViewData(
            iconData: AccountModelUtils.UI.iconViewData(accountModel: account),
            name: account.name
        )
    }

    var logoURL: URL? {
        cashbackCampaign?.promoImageURL
    }

    var campaignName: String {
        cashbackCampaign?.displayName ?? ""
    }

    var summaryTitle: String {
        Localization.promoCampaignSummaryTitle(campaignName)
    }

    var statusTitle: String {
        switch viewState {
        case .campaignNotActive: Localization.promoCampaignNotActiveTitle
        case .alreadyActivated: Localization.promoCampaignAlreadyActivatedTitle(campaignName)
        case .enrollSuccess: Localization.promoCampaignEnrollSuccessTitle(campaignName)
        case .idle, .loading, .summary, .readyToEnroll: ""
        }
    }

    var statusSubtitle: String {
        switch viewState {
        case .campaignNotActive: Localization.promoCampaignNotActiveSubtitle
        case .alreadyActivated: Localization.promoCampaignAlreadyActivatedSubtitle
        case .enrollSuccess, .idle, .loading, .summary, .readyToEnroll: ""
        }
    }

    var summaryDescription: String {
        cashbackCampaign?.summaryDescription ?? ""
    }

    var termsText: AttributedString {
        let link = Localization.promoCampaignTermsLink(campaignName)
        var attributed = AttributedString(Localization.promoCampaignTermsAgreement(link))
        attributed.font = Fonts.Bold.caption1
        attributed.foregroundColor = Colors.Text.secondary

        if let range = attributed.range(of: link) {
            attributed[range].foregroundColor = Colors.Text.primary1
            attributed[range].link = termsURL
        }

        return attributed
    }

    private let cashbackPromoService: CashbackPromoService
    private let analyticsLogger: CampaignAnalyticsLogger?
    private weak var coordinator: CampaignRoutable?

    private var campaign: CampaignBannerData?
    private var selectedToken: TokenSelectorItem?
    private var campaignLoadTask: Task<Void, Never>?
    private var enrollTask: Task<Void, Never>?

    init(
        campaignId: String,
        coordinator: CampaignRoutable?,
        cashbackPromoService: CashbackPromoService,
        analyticsLogger: CampaignAnalyticsLogger?,
        initialState: ViewState = .idle
    ) {
        self.campaignId = campaignId
        self.coordinator = coordinator
        self.cashbackPromoService = cashbackPromoService
        self.analyticsLogger = analyticsLogger
        viewState = initialState
    }

    func onAppear() {
        guard case .idle = viewState else {
            return
        }

        viewState = .loading

        campaignLoadTask = runTask(in: self) { viewModel in
            let campaign = await viewModel.cashbackPromoService.campaign(id: viewModel.campaignId)

            guard !Task.isCancelled else {
                return
            }

            await viewModel.handle(campaign: campaign)
        }
    }

    func close() {
        campaignLoadTask?.cancel()
        enrollTask?.cancel()
        coordinator?.closeCampaign()
    }

    func openLearnMore() {
        guard let cashbackCampaign else {
            return
        }

        coordinator?.openLearnMore(url: TangemBlogUrlBuilder().url(post: cashbackCampaign.blogPost))
    }

    func openTerms() {
        guard let termsURL else {
            return
        }

        coordinator?.openLearnMore(url: termsURL)
    }

    func enroll() {
        guard
            !isEnrolling,
            let selectedToken,
            let walletModel = selectedToken.kind.walletModel,
            let tokenAddress = selectedToken.tokenItem.contractAddress
        else {
            return
        }

        analyticsLogger?.logEnrollButtonClicked(tokenItem: selectedToken.tokenItem)

        let registration = CashbackRegistration(
            campaignId: campaignId,
            walletIds: userWalletRepository.models.filter { !$0.isUserWalletLocked }.map(\.userWalletId.stringValue),
            tokenReward: CashbackRegistration.TokenReward(
                networkId: selectedToken.tokenItem.networkId,
                userAddress: walletModel.defaultAddressString,
                tokenAddress: tokenAddress,
                tokenId: selectedToken.tokenItem.id
            )
        )

        isEnrolling = true

        enrollTask = runTask(in: self) { viewModel in
            do {
                let result = try await viewModel.cashbackPromoService.register(registration)

                guard !Task.isCancelled else {
                    return
                }

                await viewModel.handleRegistration(result)
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                await viewModel.handleRegistrationError()
            }
        }
    }

    func selectToken() {
        guard let campaign else {
            return
        }

        tokenSelectorViewModel = CampaignTokenSelectorViewModel(
            eligibleTokens: campaign.eligibleTokens,
            onSelect: { [weak self] item in
                self?.handleSelectedToken(item)
            },
            onClose: { [weak self] in
                self?.tokenSelectorViewModel = nil
            }
        )
    }
}

// MARK: - Private

private extension CampaignViewModel {
    var cashbackCampaign: CashbackCampaign? {
        CashbackCampaign(rawValue: campaignId)
    }

    var termsURL: URL? {
        cashbackCampaign?.termsURL
    }

    var hasMultipleAccounts: Bool {
        cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple
    }

    @MainActor
    func handle(campaign: CampaignBannerData?) {
        let now = Date()

        guard
            let campaign,
            cashbackCampaign != nil,
            campaign.campaignStatus == .active,
            campaign.startDate <= now,
            now <= campaign.endDate
        else {
            viewState = .campaignNotActive
            return
        }

        self.campaign = campaign
        viewState = .summary
        analyticsLogger?.logPromotionScreenOpened()
    }

    @MainActor
    func handleRegistration(_ result: CashbackRegistrationResult) {
        isEnrolling = false

        switch result {
        case .registered:
            viewState = .enrollSuccess
        case .alreadyEnrolled:
            viewState = .alreadyActivated
            analyticsLogger?.logAlreadyEnrolledScreenOpened()
        }
    }

    @MainActor
    func handleRegistrationError() {
        isEnrolling = false
        coordinator?.presentErrorToast(with: Localization.commonSomethingWentWrong)
    }

    func handleSelectedToken(_ item: TokenSelectorItem) {
        selectedToken = item
        selectedTokenRowViewModel = TokenSelectorItemViewModelBuilder(availabilityProvider: AvailableTokenSelectorItemAvailabilityProvider())
            .mapToTokenSelectorItemViewModel(item: item, action: {})
        tokenSelectorViewModel = nil
        viewState = .readyToEnroll
    }
}

// MARK: - SelectedAccountViewData

extension CampaignViewModel {
    struct SelectedAccountViewData {
        let iconData: AccountIconView.ViewData
        let name: String
    }
}

// MARK: - ViewState

extension CampaignViewModel {
    enum ViewState {
        case idle
        case loading
        case summary
        case readyToEnroll
        case enrollSuccess
        case alreadyActivated
        case campaignNotActive
    }
}

extension CampaignViewModel.ViewState {
    var icon: ImageType {
        switch self {
        case .alreadyActivated: DesignSystem.Icons.Info.regular28
        case .enrollSuccess: DesignSystem.Icons.Success.regular28
        case .campaignNotActive, .idle, .loading, .summary, .readyToEnroll: DesignSystem.Icons.Error.regular28
        }
    }

    var iconColor: Color {
        switch self {
        case .alreadyActivated: DesignSystem.Color.iconStatusInfo
        case .enrollSuccess: DesignSystem.Color.iconStatusSuccess
        case .campaignNotActive, .idle, .loading, .summary, .readyToEnroll: DesignSystem.Color.iconStatusWarning
        }
    }

    var iconBackgroundColor: Color {
        switch self {
        case .alreadyActivated: DesignSystem.Color.bgStatusInfoSubtle
        case .enrollSuccess: DesignSystem.Color.bgStatusSuccessSubtle
        case .campaignNotActive, .idle, .loading, .summary, .readyToEnroll: DesignSystem.Color.bgStatusWarningSubtle
        }
    }
}
