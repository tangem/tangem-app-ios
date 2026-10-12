//
//  PromoCampaignCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUI

final class PromoCampaignCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: OverlayViewPresenter
    @Injected(\.overlayViewPresentingStateProvider) private var overlayStateProvider: OverlayViewPresentingStateProvider
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.promoCampaignsRepository) private var promoCampaignsRepository: PromoCampaignsProviding
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let enrollmentService: PromoCampaignEnrolling = CommonPromoCampaignEnrollmentService()
    private let analyticsLogger: PromoCampaignAnalyticsLogging = CommonPromoCampaignAnalyticsLogger()

    private var userWalletId: UserWalletId?
    private var state = PromoCampaignFlowState()
    private var safariHandle: SafariHandle?
    private var sheetViewModel: (any FloatingSheetContentViewModel)?
    private var bag: Set<AnyCancellable> = []

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    var isStale: Bool {
        state.isStale(isSheetAlive: isSheetAlive)
    }

    private var isSheetAlive: Bool {
        sheetViewModel.map { sheetStateProvider.containsSheet(withId: $0.id) } ?? false
    }

    func start(with options: Options) {
        userWalletId = options.userWalletId
        subscribeToLock()
        subscribeToScanningAndUnlocking()

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let campaigns = await cachedCampaigns(for: options.userWalletId)

            guard !state.isFinished else {
                return
            }

            let entry = makeStateMapper().mapToEntry(campaignId: options.campaignId, campaigns: campaigns)

            state.enqueueSheet()

            switch entry {
            case .campaign(let campaign):
                let viewModel = PromoCampaignViewModel(campaign: campaign, coordinator: self)
                sheetViewModel = viewModel
                logWhenShown(.screenOpened(campaign: campaign), sheetId: viewModel.id, userWalletId: options.userWalletId)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            case .alreadyEnrolled(let campaign):
                let viewModel = PromoCampaignPrecheckViewModel(
                    state: .alreadyEnrolled(campaignName: campaign.content.title, wallets: []),
                    coordinator: self
                )
                sheetViewModel = viewModel
                logWhenShown(
                    .alreadyEnrolledScreenOpened(campaign: campaign, source: .entry),
                    sheetId: viewModel.id,
                    userWalletId: options.userWalletId
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            case .precheck(let precheckState):
                let viewModel = PromoCampaignPrecheckViewModel(state: precheckState, coordinator: self)
                sheetViewModel = viewModel
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }
        }
    }
}

// MARK: - Options

extension PromoCampaignCoordinator {
    struct Options {
        let campaignId: Int
        let userWalletId: UserWalletId
    }
}

// MARK: - Private

private extension PromoCampaignCoordinator {
    func makeStateMapper() -> PromoCampaignEnrollmentStateMapper {
        PromoCampaignEnrollmentStateMapper(userWalletModels: userWalletRepository.models)
    }

    func cachedCampaigns(for userWalletId: UserWalletId) async -> [PromoCampaign] {
        (try? await promoCampaignsRepository.campaignsPublisher(for: userWalletId).async()) ?? []
    }

    func subscribeToLock() {
        userWalletRepository.eventProvider
            .filter { $0 == .locked }
            .first()
            .sink { [weak self] _ in
                self?.finish()
            }
            .store(in: &bag)
    }

    func subscribeToScanningAndUnlocking() {
        let didStart = Publishers.Merge(
            NotificationCenter.default.publisher(for: .cardSessionDidStart),
            NotificationCenter.default.publisher(for: .mobileUnlockDidStart)
        )
        .map { _ in true }

        let didFinish = Publishers.Merge(
            NotificationCenter.default.publisher(for: .cardSessionDidFinish),
            NotificationCenter.default.publisher(for: .mobileUnlockDidFinish)
        )
        .map { _ in false }

        Publishers.Merge(didStart, didFinish)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { coordinator, isActive in
                MainActor.assumeIsolated {
                    coordinator.scanningOrUnlockingChanged(isActive: isActive)
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func scanningOrUnlockingChanged(isActive: Bool) {
        guard let result = state.changeScanningOrUnlocking(isActive: isActive) else {
            return
        }

        showResult(result)
    }

    func logWhenShown(_ event: PromoCampaignAnalyticsEvent, sheetId: String, userWalletId: UserWalletId) {
        sheetStateProvider.activeSheetIdPublisher
            .first { $0 == sheetId }
            .sink { [analyticsLogger] _ in
                analyticsLogger.log(event, userWalletId: userWalletId)
            }
            .store(in: &bag)
    }

    func subscribeToResultDismiss() {
        overlayStateProvider.presentedOverlayIdPublisher
            .drop(while: { $0 != Constants.resultOverlayId })
            .filter { $0 != Constants.resultOverlayId }
            .first()
            .sink { [weak self] _ in
                self?.finish()
            }
            .store(in: &bag)
    }

    func resumeSheetAfterSafari() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            safariHandle = nil

            guard !state.isFinished, state.isSafariPresented else {
                return
            }

            floatingSheetPresenter.resumeSheetsDisplaying()

            if state.closeSafari(isSheetAlive: isSheetAlive) {
                finish()
            }
        }
    }

    @MainActor
    func showResult(_ result: PromoCampaignFlowState.Result) {
        let ownsSheet = state.finishEnrollment(isSheetAlive: isSheetAlive)

        guard canPresentResult() else {
            if ownsSheet {
                removeOwnSheet()
            }

            finish()
            return
        }

        floatingSheetPresenter.pauseSheetsDisplaying()
        state.pauseSheetsForResult()

        if ownsSheet {
            removeOwnSheet()
        }

        let viewModel = PromoCampaignEnrollmentResultViewModel(
            state: makeStateMapper().mapToResultState(result.outcome, campaign: result.campaign),
            coordinator: self
        )

        overlayViewPresenter.present(OverlayView(
            id: Constants.resultOverlayId,
            view: PromoCampaignEnrollmentResultView(viewModel: viewModel),
            style: .fullScreenCover
        ))

        if case .alreadyEnrolled = result.outcome, let userWalletId {
            analyticsLogger.log(.alreadyEnrolledScreenOpened(campaign: result.campaign, source: .enrollResponse), userWalletId: userWalletId)
        }

        subscribeToResultDismiss()
    }

    func canPresentResult() -> Bool {
        guard let userWalletId, !userWalletRepository.isLocked else {
            return false
        }

        return userWalletRepository.models.contains { $0.userWalletId == userWalletId && !$0.isUserWalletLocked }
    }

    @MainActor
    func removeOwnSheet() {
        guard let sheetId = sheetViewModel?.id else {
            return
        }

        floatingSheetPresenter.removeSheet(withId: sheetId)
    }

    func finish() {
        guard state.finish() else {
            return
        }

        bag.removeAll()
        sheetViewModel = nil

        if state.isSheetsDisplayingPausedForResult, !userWalletRepository.isLocked {
            Task { @MainActor [floatingSheetPresenter] in
                floatingSheetPresenter.resumeSheetsDisplaying()
            }
        }

        dismiss()
    }
}

// MARK: - PromoCampaignRoutable

extension PromoCampaignCoordinator: PromoCampaignRoutable {
    func closeCampaign() {
        Task { @MainActor [weak self] in
            guard let self, state.closeSheet() else {
                return
            }

            removeOwnSheet()

            if !state.isEnrolling {
                finish()
            }
        }
    }

    func openLearnMore(url: URL) {
        Task { @MainActor [weak self] in
            guard let self, state.openSafari() else {
                return
            }

            floatingSheetPresenter.pauseSheetsDisplaying()

            safariHandle = safariManager.openURL(
                url,
                configuration: .init(),
                onDismiss: { [weak self] in self?.resumeSheetAfterSafari() },
                onSuccess: { [weak self] _ in self?.resumeSheetAfterSafari() }
            )
        }
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    func enrollInPromoCampaign(_ campaign: PromoCampaign, payoutToken: TokenSelectorItem?) -> Bool {
        guard let userWalletId, state.startEnrollment() else {
            return false
        }

        let payout = makePayoutSelection(from: payoutToken)

        Task { @MainActor [weak self, enrollmentService] in
            let outcome = await enrollmentService.enroll(in: campaign, from: userWalletId, payout: payout)

            guard let self, let result = state.receiveResult(.init(outcome: outcome, campaign: campaign)) else {
                return
            }

            showResult(result)
        }

        return true
    }

    private func makePayoutSelection(from payoutToken: TokenSelectorItem?) -> PromoCampaignPayoutSelection? {
        guard let payoutToken, let walletModel = payoutToken.kind.walletModel else {
            return nil
        }

        return PromoCampaignPayoutSelection(tokenItem: payoutToken.tokenItem, address: walletModel.defaultAddressString)
    }
}

// MARK: - PromoCampaignEnrollmentResultRoutable

extension PromoCampaignCoordinator: PromoCampaignEnrollmentResultRoutable {
    func closePromoCampaignEnrollmentResult() {
        Task { @MainActor [weak self] in
            self?.overlayViewPresenter.dismiss()
        }
    }
}

// MARK: - Constants

private extension PromoCampaignCoordinator {
    enum Constants {
        static let toastTopPadding: CGFloat = 52
        static let resultOverlayId = "promo_campaign_enrollment_result"
    }
}
