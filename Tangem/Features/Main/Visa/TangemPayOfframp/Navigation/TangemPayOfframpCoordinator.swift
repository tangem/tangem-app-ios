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
import TangemLocalization
import TangemPay
import TangemUI

final class TangemPayOfframpCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: WithdrawHubViewModel?
    @Published var path: [Route] = []
    @Published var successStatusModel: TransferSuccessStatusView.Model?
    @Published var failedStatus: FailedStatus?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Shared state

    private(set) var recentRecipientsStore: TangemPayRecentRecipientsStore?
    private(set) var optionsStore: TangemPayOfframpOptionsStore?
    private(set) var geoStore: TangemPayGeoStore?
    private(set) var orderBuilder: TangemPayOfframpOrderBuilder?
    private(set) var sendUseCase: TangemPayOffRampSendUseCase?
    private(set) var hasNFCInteraction = false

    private var orderService: (any TangemPayOfframpOrderService)?
    private var orderSigner: (any TangemPayOfframpOrderSigning)?
    @Published private(set) var transferInputViewModel: TransferInputViewModel?

    // MARK: - Geo selection

    @Published var isGeoSelectionPresented = false

    private var geoSelectionStart: TangemPayOfframpGeoSelectionCoordinatorView.Start?
    private var geoSelectionCompletion: ((TangemPayOfframpGeoSelectionCoordinatorView.Output) -> Void)?

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

        orderService = CommonTangemPayOfframpOrderService(
            customerService: options.tangemPayAccount.customerService
        )

        orderSigner = options.tangemPayAccount.offrampOrderSigner

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

        // [REDACTED_TODO_COMMENT]
        // let repository = CommonTangemPayGeoRepository()
        let repository = MockTangemPayGeoRepository()
        geoStore = TangemPayGeoStore(repository: repository)

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
        guard let optionsStore,
              let orderService,
              let orderSigner,
              let recentRecipientsStore
        else {
            return
        }

        let orderBuilder = TangemPayOfframpOrderBuilder(recipient: recipient)
        self.orderBuilder = orderBuilder

        let savedRecipientName = savedRecipientName(for: recipient)

        Task { @MainActor [weak self] in
            guard let self else { return }

            sendUseCase = TangemPayOffRampSendUseCase(
                orderService: orderService,
                orderSigner: orderSigner,
                recentRecipientsStore: recentRecipientsStore
            )

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
        case swap
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
                coordinator.sendUseCase = nil
                coordinator.transferInputViewModel = nil
            }
            .store(in: &bag)

        $path
            .map { $0.contains(.swap) }
            .removeDuplicates()
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.sendCoordinator = nil
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
        case .selectCountry(let selectedCountryCode, let selectedRegionCode, let completion):
            presentCountrySelection(
                selectedCountryCode: selectedCountryCode,
                selectedRegionCode: selectedRegionCode,
                completion: completion
            )

        case .selectRegion(let countryCode, let selectedCode, let completion):
            presentRegionSelection(countryCode: countryCode, selectedCode: selectedCode, completion: completion)

        case .savedRecipientSelected:
            restartOnSavedRecipient()

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
        case .selectRegion(let countryCode, let selectedCode, let completion):
            presentRegionSelection(countryCode: countryCode, selectedCode: selectedCode, completion: completion)

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

        case .sent(let model):
            successStatusModel = model

        case .failed(let model, let onRetry):
            failedStatus = FailedStatus(model: model, onRetry: onRetry)

        case .close:
            dismiss(with: nil)
        }
    }

    func retryAfterFailedStatus() {
        let onRetry = failedStatus?.onRetry
        failedStatus = nil

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.failedStatusDismissDelay))
            onRetry?()
        }
    }
}

// MARK: - Failed status

extension TangemPayOfframpCoordinator {
    struct FailedStatus: Identifiable {
        let id = UUID()
        let model: TransferFailedStatusView.Model
        let onRetry: (() -> Void)?

        var canRetry: Bool {
            onRetry != nil
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

    func restartOnSavedRecipient() {
        Task { @MainActor [weak self] in
            guard
                let self,
                let orderBuilder,
                let optionsStore,
                let index = path.lastIndex(of: .transferInput)
            else {
                return
            }

            transferInputViewModel = TransferInputFactory.makeViewModel(
                orderBuilder: orderBuilder,
                optionsStore: optionsStore,
                recipient: orderBuilder.recipient,
                savedRecipientName: savedRecipientName(for: orderBuilder.recipient),
                output: { [weak self] in
                    self?.handle($0)
                }
            )

            path.removeSubrange((index + 1)...)
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
    func makeGeoSelectionView() -> some View {
        if let geoStore, let geoSelectionStart {
            TangemPayOfframpGeoSelectionCoordinatorView(
                store: geoStore,
                start: geoSelectionStart,
                output: { [weak self] in self?.handle($0) }
            )
        }
    }

    func onGeoSelectionDismiss() {
        geoSelectionStart = nil
        geoSelectionCompletion = nil
    }
}

private extension TangemPayOfframpCoordinator {
    func presentGeoSelection(
        start: TangemPayOfframpGeoSelectionCoordinatorView.Start,
        completion: @escaping (TangemPayOfframpGeoSelectionCoordinatorView.Output) -> Void
    ) {
        geoSelectionStart = start
        geoSelectionCompletion = completion
        isGeoSelectionPresented = true
    }

    func presentCountrySelection(
        selectedCountryCode: String?,
        selectedRegionCode: String?,
        completion: @escaping (TangemPayGeoCountry, TangemPayGeoRegion?) -> Void
    ) {
        presentGeoSelection(
            start: .country(selectedCountryCode: selectedCountryCode, selectedRegionCode: selectedRegionCode)
        ) { output in
            switch output {
            case .country(let country):
                completion(country, nil)

            case .countryWithRegion(let country, let region):
                completion(country, region)

            case .region, .closed:
                break
            }
        }
    }

    func presentRegionSelection(
        countryCode: String,
        selectedCode: String?,
        completion: @escaping (TangemPayGeoRegion) -> Void
    ) {
        presentGeoSelection(start: .region(countryCode: countryCode, selectedCode: selectedCode)) { output in
            switch output {
            case .region(let region):
                completion(region)

            case .country, .countryWithRegion, .closed:
                break
            }
        }
    }

    func handle(_ output: TangemPayOfframpGeoSelectionCoordinatorView.Output) {
        switch output {
        case .country, .countryWithRegion, .region:
            geoSelectionCompletion?(output)

        case .closed:
            break
        }

        isGeoSelectionPresented = false
    }
}

// MARK: - Withdraw hub output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: WithdrawHubViewModel.Output) {
        switch output {
        case .withdraw(let parameters):
            openSwap(parameters: parameters)

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
            switch options {
            case .none, .closeButtonTap, .openSwap:
                self?.dismiss(with: nil)
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
        path.append(.swap)
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

// MARK: - Constants

private extension TangemPayOfframpCoordinator {
    enum Constants {
        static let failedStatusDismissDelay: TimeInterval = 0.3
    }
}
