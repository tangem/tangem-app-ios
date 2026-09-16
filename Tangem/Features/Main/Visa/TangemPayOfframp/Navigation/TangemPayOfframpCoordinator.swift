//
//  TangemPayOfframpCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemPay
import TangemUI

final class TangemPayOfframpCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: WithdrawHubViewModel?
    @Published var path: [Route] = []

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Shared state

    private(set) var recentRecipientsStore: TangemPayRecentRecipientsStore?
    private(set) var optionsStore: TangemPayOfframpOptionsStore?
    private(set) var geoStore: TangemPayGeoStore?
    private(set) var orderBuilder: TangemPayOfframpOrderBuilder?
    private(set) var hasNFCInteraction = false
    @Published private(set) var transferInputViewModel: TransferInputViewModel?

    // MARK: - Geo selection

    @Published var isCountrySelectionPresented = false
    @Published var isRegionSelectionPresented = false

    private var countrySelectionCompletion: ((TangemPayGeoCountry) -> Void)?
    private var regionSelectionCompletion: ((TangemPayGeoRegion) -> Void)?
    private var regionSelectionCountryCode: String?

    private var bag: Set<AnyCancellable> = []

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        hasNFCInteraction = options.hasNFCInteraction

        let recentRecipientsStore = TangemPayRecentRecipientsStore(
            repository: CommonTangemPayBankAccountsRepository(
                customerService: options.tangemPayAccount.customerService
            ),
            cacheStorage: AppSettings.shared,
            customerWalletId: options.tangemPayAccount.userWalletId.stringValue
        )
        self.recentRecipientsStore = recentRecipientsStore

        let optionsStore = TangemPayOfframpOptionsStore(
            optionsRepository: CommonTangemPayOfframpOptionsRepository(
                customerService: options.tangemPayAccount.customerService
            ),
            accountTokensProvider: { [tangemPayAccount = options.tangemPayAccount] in
                await Self.accountTokens(for: tangemPayAccount)
            }
        )
        self.optionsStore = optionsStore

        geoStore = TangemPayGeoStore(repository: CommonTangemPayGeoRepository())

        rootViewModel = WithdrawHubViewModel(
            withdrawFlowResolver: TangemPayWithdrawFlowResolver(
                fundingFlowBuilder: options.fundingFlowBuilder,
                withdrawAvailabilityProvider: options.tangemPayAccount.withdrawAvailabilityProvider
            ),
            recentRecipientsStore: recentRecipientsStore,
            optionsStore: optionsStore,
            output: { [weak self] in
                self?.handle($0)
            }
        )

        bind()
    }

    func startWizard(recipient: TangemPayOfframpRecipient) {
        guard let optionsStore else { return }

        let orderBuilder = TangemPayOfframpOrderBuilder(recipient: recipient)
        self.orderBuilder = orderBuilder

        let savedRecipientName = savedRecipientName(for: recipient)

        Task { @MainActor [weak self] in
            guard let self else { return }

            transferInputViewModel = TransferInputFactory.makeViewModel(
                orderBuilder: orderBuilder,
                optionsStore: optionsStore,
                recipient: recipient,
                savedRecipientName: savedRecipientName,
                output: { [weak self] in
                    self?.handle($0)
                }
            )

            path.append(.transferInput)
        }
    }
}

// MARK: - Coordinator Options

extension TangemPayOfframpCoordinator {
    struct Options {
        let tangemPayAccount: TangemPayAccount
        let fundingFlowBuilder: TangemPayFundingFlowBuilder
        let hasNFCInteraction: Bool
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - Route

extension TangemPayOfframpCoordinator {
    enum Route: Hashable {
        case recentRecipients
        case transferInput
        case transferType
        case accountType
        case personalDetails(Mode)
        case bankDetails(Mode)
        case transferConfirmation
    }

    enum Mode: Hashable {
        case wizard
        case edit
    }
}

// MARK: - Route traits

extension TangemPayOfframpCoordinator.Route {
    var isPersonalDetails: Bool {
        if case .personalDetails = self {
            return true
        }

        return false
    }
}

// MARK: - Account tokens

private extension TangemPayOfframpCoordinator {
    @MainActor
    static func accountTokens(for account: TangemPayAccount) async -> [TangemPayAccountToken] {
        if account.networks.isEmpty {
            await account.loadBalance()
        }

        return TangemPayAccountTokensResolver().resolve(networks: account.networks)
    }
}

// MARK: - Wizard lifetime

private extension TangemPayOfframpCoordinator {
    func bind() {
        $path
            .map { $0.contains(.transferInput) }
            .removeDuplicates()
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.orderBuilder = nil
                coordinator.transferInputViewModel = nil
            }
            .store(in: &bag)

        $path
            .map { $0.contains(where: \.isPersonalDetails) }
            .removeDuplicates()
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.geoStore?.loadCountries()
            }
            .store(in: &bag)
    }

    func savedRecipientName(for recipient: TangemPayOfframpRecipient) -> String? {
        savedRecipient(for: recipient)
            .map { TangemPayRecipientNameFormatter.name(for: $0, style: .full) }
    }

    func savedRecipient(for recipient: TangemPayOfframpRecipient) -> TangemPayBankAccountResponse? {
        guard case .saved(let bankAccountId) = recipient else { return nil }

        return recentRecipientsStore?.recipients.first { $0.id == bankAccountId }
    }
}

// MARK: - Active recipient

extension TangemPayOfframpCoordinator {
    var activeSavedRecipient: TangemPayBankAccountResponse? {
        orderBuilder.flatMap { savedRecipient(for: $0.recipient) }
    }
}

// MARK: - Transfer input output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: TransferInputViewModel.Output) {
        switch output {
        case .continueWizard:
            if path.contains(.transferConfirmation) {
                popToConfirmation()
            } else {
                continueAfterTransferInput()
            }

        case .close:
            dismiss(with: nil)
        }
    }
}

// MARK: - Wizard step output

extension TangemPayOfframpCoordinator {
    func handle(_ output: TransferTypeViewModel.Output) {
        switch output {
        case .continueWizard:
            path.append(.accountType)

        case .close:
            dismiss(with: nil)
        }
    }

    func handle(_ output: AccountTypeViewModel.Output) {
        switch output {
        case .continueWizard:
            path.append(.personalDetails(.wizard))

        case .close:
            dismiss(with: nil)
        }
    }

    func handle(_ output: PersonalDetailsViewModel.Output, mode: Mode) {
        switch output {
        case .selectCountry(let completion):
            presentCountrySelection(completion: completion)

        case .selectRegion(let countryCode, let completion):
            presentRegionSelection(countryCode: countryCode, completion: completion)

        case .continueWizard:
            switch mode {
            case .wizard:
                path.append(.bankDetails(.wizard))
            case .edit:
                popToConfirmation()
            }

        case .close:
            dismiss(with: nil)
        }
    }

    func handle(_ output: BankDetailsViewModel.Output, mode: Mode) {
        switch output {
        case .selectRegion(let countryCode, let completion):
            presentRegionSelection(countryCode: countryCode, completion: completion)

        case .continueWizard:
            switch mode {
            case .wizard:
                path.append(.transferConfirmation)
            case .edit:
                popToConfirmation()
            }

        case .close:
            dismiss(with: nil)
        }
    }

    func handle(_ output: TransferConfirmationViewModel.Output) {
        switch output {
        case .edit(let target):
            path.append(route(for: target))

        case .close:
            dismiss(with: nil)
        }
    }
}

// MARK: - Wizard routing

private extension TangemPayOfframpCoordinator {
    func continueAfterTransferInput() {
        guard let orderBuilder else { return }

        switch orderBuilder.recipient {
        case .newIndividual:
            path.append(.transferType)

        case .newBusiness:
            path.append(.accountType)

        case .saved:
            path.append(.transferConfirmation)
        }
    }

    func popToConfirmation() {
        guard let index = path.lastIndex(of: .transferConfirmation) else { return }

        path.removeSubrange((index + 1)...)
    }

    func route(for target: TransferConfirmationEditTarget) -> Route {
        switch target {
        case .amount: .transferInput
        case .personalDetails: .personalDetails(.edit)
        case .bankDetails: .bankDetails(.edit)
        }
    }
}

// MARK: - Geo selection

extension TangemPayOfframpCoordinator {
    @MainActor
    @ViewBuilder
    func makeCountrySelectionView() -> some View {
        if let geoStore {
            CountrySelectionFactory.makeView(
                store: geoStore,
                // [REDACTED_TODO_COMMENT]
                configuration: GeoSelectionConfiguration(
                    title: "Country",
                    suggestedSectionTitle: nil,
                    allSectionTitle: nil,
                    showsSuggestedSection: false,
                    showsBackButton: false
                ),
                output: { [weak self] in self?.handle($0) }
            )
        }
    }

    @MainActor
    @ViewBuilder
    func makeRegionSelectionView() -> some View {
        if let geoStore, let regionSelectionCountryCode {
            RegionSelectionFactory.makeView(
                store: geoStore,
                countryCode: regionSelectionCountryCode,
                // [REDACTED_TODO_COMMENT]
                configuration: GeoSelectionConfiguration(
                    title: "Region",
                    suggestedSectionTitle: nil,
                    allSectionTitle: nil,
                    showsSuggestedSection: false,
                    showsBackButton: false
                ),
                output: { [weak self] in self?.handle($0) }
            )
        }
    }
}

private extension TangemPayOfframpCoordinator {
    func presentCountrySelection(completion: @escaping (TangemPayGeoCountry) -> Void) {
        countrySelectionCompletion = completion
        isCountrySelectionPresented = true
    }

    func presentRegionSelection(countryCode: String, completion: @escaping (TangemPayGeoRegion) -> Void) {
        regionSelectionCountryCode = countryCode
        regionSelectionCompletion = completion
        isRegionSelectionPresented = true
    }

    func handle(_ output: CountrySelectionViewModel.Output) {
        switch output {
        case .selected(let country):
            countrySelectionCompletion?(country)

        case .closed:
            break
        }

        countrySelectionCompletion = nil
        isCountrySelectionPresented = false
    }

    func handle(_ output: RegionSelectionViewModel.Output) {
        switch output {
        case .selected(let region):
            regionSelectionCompletion?(region)

        case .closed:
            break
        }

        regionSelectionCompletion = nil
        isRegionSelectionPresented = false
    }
}

// MARK: - Withdraw hub output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: WithdrawHubViewModel.Output) {
        switch output {
        case .withdrawNote(let parameters):
            Task { @MainActor in
                let viewModel = TangemPayWithdrawNoteSheetViewModel(
                    parameters: parameters,
                    coordinator: self
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .withdrawInProgress:
            Task { @MainActor in
                let viewModel = TangemPayWithdrawInProgressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .noDepositAddress:
            Task { @MainActor in
                let viewModel = TangemPayNoDepositAddressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .allRecipients:
            path.append(.recentRecipients)

        case .startWizard(let recipient):
            startWizard(recipient: recipient)

        case .close:
            dismiss(with: nil)
        }
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] options in
            self?.sendCoordinator = nil

            switch options {
            case .none, .closeButtonTap, .openSwap:
                break
            case .openFeeCurrency(let feeCurrency):
                self?.dismiss(with: feeCurrency)
            }
        }

        let coordinator = SendCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(type: .swap(parameters), source: .main))
        sendCoordinator = coordinator
    }
}

// MARK: - TangemPayWithdrawNoteSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawNoteSheetRoutable {
    func closeWithdrawNoteSheetPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openWithdrawal(parameters: PredefinedSwapParameters) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            openSwap(parameters: parameters)
        }
    }
}

// MARK: - TangemPayWithdrawInProgressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayNoDepositAddressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
