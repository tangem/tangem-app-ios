//
//  TangemPayOnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI
import TangemVisa

protocol TangemPayOnboardingRoutable: AnyObject {
    func openWalletSelector(
        from: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    )
    func openResidency(interactor: any TangemPayResidencyInteractor)
}

final class TangemPayOnboardingCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TangemPayOnboardingViewModel?
    @Published var residencyCoordinator: TangemPayResidencyCoordinator?

    private var kycLaunchTask: Task<Void, Never>?

    private lazy var geoStore = TangemPayGeoStore(
        repository: CommonTangemPayGeoRepository()
    )

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        kycLaunchTask?.cancel()
    }

    func start(with options: Options) {
        prefetchCountriesIfNeeded()

        switch options.entry {
        case .offer(let source, let availableSelection):
            rootViewModel = .init(
                source: source,
                availableSelection: availableSelection,
                coordinator: self,
                closeOfferScreen: { [weak self] in
                    self?.dismiss(with: ())
                }
            )

        case .residency(let interactor):
            openResidency(interactor: interactor)
        }
    }
}

extension TangemPayOnboardingCoordinator: TangemPayOnboardingRoutable {
    func openWalletSelector(
        from walletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    ) {
        let _onSelect: (UserWalletModel) -> Void = { [weak self] walletModel in
            self?.dismissActiveSheet()
            onSelect(walletModel)
        }

        let walletSelectorViewModel = TangemPayWalletSelectorViewModel(
            userWalletModels: walletModels,
            onSelect: _onSelect
        ) { [weak self] in
            self?.dismissActiveSheet()
        }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: walletSelectorViewModel)
        }
    }

    func openResidency(interactor: any TangemPayResidencyInteractor) {
        let dismissAction: Action<TangemPayResidencyCoordinator.DismissOptions?> = { [weak self] options in
            switch options {
            case .available:
                self?.launchKYC(interactor: interactor)

            case .joinedWaitlist:
                self?.kycLaunchTask?.cancel()
                self?.dismiss(with: ())
                Toast(view: SuccessToast(text: Localization.tangempayWaitlistJoinedMessage))
                    .present(layout: .top(padding: 12), type: .temporary())

            case .closed, .none:
                self?.kycLaunchTask?.cancel()
                self?.dismiss(with: ())
            }
        }

        let coordinator = TangemPayResidencyCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(product: .paymentAccount, geoStore: geoStore, interactor: interactor))
        residencyCoordinator = coordinator
    }

    private func launchKYC(interactor: any TangemPayResidencyInteractor) {
        guard kycLaunchTask == nil else {
            return
        }

        kycLaunchTask = runTask { [weak self] in
            do {
                try await interactor.launchKYC { [weak self] in
                    await self?.dismissOnMain()
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                VisaLogger.error("Failed to launch Tangem Pay KYC after the residency step", error: error)
                await self?.dismissAfterKYCLaunchFailure()
            }
        }
    }

    @MainActor
    private func dismissOnMain() {
        dismiss(with: ())
    }

    @MainActor
    private func dismissAfterKYCLaunchFailure() {
        dismiss(with: ())
        Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
            .present(layout: .top(padding: 20), type: .temporary())
    }

    private func prefetchCountriesIfNeeded() {
        guard FeatureProvider.isAvailable(.tangemPayChooseCountry) else {
            return
        }

        geoStore.loadCountries()
    }

    private func dismissActiveSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension TangemPayOnboardingCoordinator {
    struct Options {
        let entry: Entry

        init(source: TangemPayOnboardingSource, availableSelection: TangemPayWalletSelectionType) {
            entry = .offer(source: source, availableSelection: availableSelection)
        }

        init(residencyInteractor: any TangemPayResidencyInteractor) {
            entry = .residency(residencyInteractor)
        }
    }

    enum Entry {
        case offer(source: TangemPayOnboardingSource, availableSelection: TangemPayWalletSelectionType)
        case residency(any TangemPayResidencyInteractor)
    }

    typealias DismissOptions = Void
}
