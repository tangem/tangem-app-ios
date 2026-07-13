//
//  SendDestinationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation

class SendDestinationViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    var destinationAddressSectionType: [DestinationAddressSectionType] {
        var section: [DestinationAddressSectionType] = [.destinationAddress(destinationAddressViewModel)]
        if let destinationResolvedAddress {
            section.append(.destinationResolvedAddress(destinationResolvedAddress))
        }
        return section
    }

    var hasNonEmptyDestinationAddress: Bool {
        !destinationAddressViewModel.address.string.isEmpty
    }

    @Published var additionalFieldViewModel: SendDestinationAdditionalFieldViewModel?

    @Published var shouldShowSuggestedDestination: Bool = true
    @Published var suggestedDestinationViewModel: SendDestinationSuggestedViewModel?
    @Published var addressBookViewModel: SendDestinationAddressBookViewModel?

    @Published var networkName: String = ""

    @Published private var destinationAddressViewModel: SendDestinationAddressViewModel
    @Published private var destinationResolvedAddress: String?

    // MARK: - Private

    private let interactor: SendDestinationInteractor
    private let sendQRCodeService: SendQRCodeService
    private let analyticsLogger: SendDestinationAnalyticsLogger
    private let contactMatcher = AddressBookContactMatcher()
    private let hasContactMatchesSubject = CurrentValueSubject<Bool, Never>(false)
    private weak var router: SendDestinationRoutable?

    private var updatingTask: Task<Void, Error>?
    private var updatingDestinationString: String?
    private var bag: Set<AnyCancellable> = []

    private var hasLoggedAddressBookWidgetShown = false

    weak var stepRouter: SendDestinationStepRoutable?

    // MARK: - Methods

    init(
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable
    ) {
        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.analyticsLogger = analyticsLogger
        self.router = router

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )

        destinationAddressViewModel.router = self
        bind()
    }

    func onAddressBookWidgetShown() {
        guard !hasLoggedAddressBookWidgetShown else {
            return
        }

        hasLoggedAddressBookWidgetShown = true
        analyticsLogger.logAddressBookWidgetShown()
    }

    func onAppear() {
        interactor.preloadTransactionHistoryIfNeeded()
    }

    func setIgnoreDestinationAddressClearButton(_ ignore: Bool) {
        destinationAddressViewModel.update(shouldIgnoreClearButton: ignore)
    }

    private func updateView(tokenItem: TokenItem) {
        networkName = tokenItem.networkName
        destinationAddressViewModel.textViewModel.placeholder = makePlaceholder(tokenItem: tokenItem)
        additionalFieldViewModel = makeAdditionalFieldViewModel(tokenItem: tokenItem)
    }

    private func makePlaceholder(tokenItem: TokenItem) -> String {
        switch tokenItem.blockchain {
        case .ethereum: Localization.sendEnterAddressFieldEns
        default: Localization.sendEnterAddressField
        }
    }

    private func makeAdditionalFieldViewModel(tokenItem: TokenItem) -> SendDestinationAdditionalFieldViewModel? {
        let viewModel = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain).map { additionalFieldType in
            SendDestinationAdditionalFieldViewModel(title: additionalFieldType.name)
        }

        viewModel?.textPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, field in
                viewModel.interactor.update(additionalField: field)
            }
            .store(in: &bag)

        return viewModel
    }

    private func bind() {
        // MARK: - Token

        interactor.tokenItemPublisher
            // Exclude unnecessary updating
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.updateView(tokenItem: $1) }
            .store(in: &bag)

        // MARK: - Destination

        destinationAddressViewModel
            .addressPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.addressDidChanged(destination: $1) }
            .store(in: &bag)

        interactor.destinationResolvedAddress
            .receiveOnMain()
            .assign(to: &$destinationResolvedAddress)

        interactor.isValidatingDestination
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, isValidating in
                viewModel.destinationAddressViewModel.update(isValidating: isValidating)
            }
            .store(in: &bag)

        Publishers
            .CombineLatest(interactor.destinationError, hasContactMatchesSubject)
            .map { error, hasContactMatches -> String? in hasContactMatches ? nil : error }
            .map { error -> AnyPublisher<String?, Never> in
                guard let error else {
                    return .just(output: nil)
                }

                return Just<String?>(error)
                    .delay(for: .milliseconds(Constants.destinationErrorDisplayDelay), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.destinationAddressViewModel.update(error: error)
            }
            .store(in: &bag)

        // MARK: - Transaction History

        Publishers
            .CombineLatest(interactor.transactionHistoryPublisher, interactor.suggestedWalletsPublisher)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, args in
                let (recentTransactions, suggestedWallets) = args
                viewModel.setupSuggestedDestination(recentTransactions: recentTransactions, suggestedWallets: suggestedWallets)
            }
            .store(in: &bag)

        let contactsQueryPublisher = destinationAddressViewModel
            .addressPublisher()
            .map(\.string)
            .debounce(for: .milliseconds(Constants.contactsFilterDebounce), scheduler: DispatchQueue.main)
            .prepend("")
            .removeDuplicates()

        Publishers
            .CombineLatest(interactor.addressBookContactsPublisher, contactsQueryPublisher)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, args in
                let (contacts, query) = args
                let filtered = contacts.filter { viewModel.contactMatcher.matches($0.contact, query: query) }
                viewModel.hasContactMatchesSubject.send(!query.trimmed().isEmpty && !filtered.isEmpty)
                viewModel.setupAddressBookContacts(filtered)
            }
            .store(in: &bag)

        interactor.destinationValid
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, destinationValid in
                let text = viewModel.destinationAddressViewModel.text.value
                viewModel.shouldShowSuggestedDestination = text.isEmpty || !destinationValid
            }
            .store(in: &bag)

        // MARK: - QR Code Service

        sendQRCodeService
            .qrCodeDestination
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, address in
                viewModel.destinationAddressViewModel.update(address: .init(string: address, source: .qrCode))
            }
            .store(in: &bag)

        sendQRCodeService
            .qrCodeAdditionalField
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, field in
                viewModel.additionalFieldViewModel?.update(text: field)
            }
            .store(in: &bag)

        // MARK: - Additional Field

        interactor
            .canEmbedAdditionalField
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, canEmbed in
                if !canEmbed {
                    viewModel.additionalFieldViewModel?.update(text: "")
                }

                viewModel.additionalFieldViewModel?.update(disabled: !canEmbed)
            }
            .store(in: &bag)

        interactor
            .destinationAdditionalFieldError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.additionalFieldViewModel?.update(error: error)
            }
            .store(in: &bag)
    }

    private func setupSuggestedDestination(
        recentTransactions: [SendDestinationSuggestedTransactionRecord],
        suggestedWallets: [SendDestinationSuggestedWallet]
    ) {
        let hasSuggestions = !suggestedWallets.isEmpty || !recentTransactions.isEmpty

        guard hasSuggestions else {
            suggestedDestinationViewModel = nil
            return
        }

        suggestedDestinationViewModel = SendDestinationSuggestedViewModel(
            wallets: suggestedWallets,
            recentTransactions: recentTransactions
        ) { [weak self] destination in
            self?.userDidTapSuggestedDestination(destination)
        }
    }

    private func userDidTapSuggestedDestination(_ suggestedDestination: SendDestinationSuggested) {
        if let userWalletInfo = suggestedDestination.userWalletInfo,
           let alert = UserWalletBackupStatusHelper().alert(for: userWalletInfo) {
            alertPresenter.present(alert: alert)
            return
        }

        FeedbackGenerator.success()

        analyticsLogger.setDestinationAnalyticsProvider(suggestedDestination.accountModelAnalyticsProvider)

        let destination = SendDestinationAddressViewModel.Address(
            string: suggestedDestination.address,
            source: suggestedDestination.type.source
        )

        destinationAddressViewModel.update(address: destination)

        if let additionalField = suggestedDestination.additionalField {
            additionalFieldViewModel?.update(text: additionalField)
        }

        // Waiting when updatingTask is finished
        Task { @MainActor in
            try await addressDidChanged(destination: destination).value
            stepRouter?.destinationStepFulfilled()
        }
    }

    private func setupAddressBookContacts(_ contacts: [SendDestinationAddressBookContact]) {
        guard !contacts.isEmpty else {
            addressBookViewModel = nil
            return
        }

        addressBookViewModel = SendDestinationAddressBookViewModel(
            contacts: contacts,
            limit: Constants.addressBookContactsLimit,
            tapAction: { [weak self] contact in
                self?.userDidTapAddressBookContact(contact)
            },
            viewAllAction: { [weak self] in
                self?.openAddressBookViewAll()
            }
        )
    }

    private func openAddressBookViewAll() {
        guard let addressBooksProvider = interactor.addressBooksProvider else {
            return
        }

        router?.openAddressBookViewAll(provider: addressBooksProvider, output: self)
    }

    private func userDidTapAddressBookContact(_ contact: AddressBookContact) {
        analyticsLogger.logAddressBookContactSelected(contact)
        let groups = contact.entries.groupedByAddress
        if let single = groups.singleElement {
            applyAddressBookAddress(single, from: contact)
            return
        }

        router?.openAddressBookChooseAddress(contact: contact, output: self)
    }

    private func applyAddressBookAddress(_ addressGroup: AddressBookContactAddressGroup, from contact: AddressBookContact) {
        analyticsLogger.logAddressBookAddressSubstituted(contact)

        FeedbackGenerator.success()

        let destination = SendDestinationAddressViewModel.Address(
            string: addressGroup.address,
            source: .addressBook
        )

        destinationAddressViewModel.update(address: destination)
        additionalFieldViewModel?.update(text: addressGroup.memo ?? "")

        // Waiting when updatingTask is finished
        Task { @MainActor in
            try await addressDidChanged(destination: destination).value
            stepRouter?.destinationStepFulfilled()
        }
    }

    @discardableResult
    func addressDidChanged(destination: SendDestinationAddressViewModel.Address) -> Task<Void, Error> {
        if let updatingTask, !updatingTask.isCancelled, updatingDestinationString == destination.string {
            return updatingTask
        }

        let hasValue = !destination.string.isEmpty
        let shouldResolve = interactor.shouldResolve(address: destination.string)
        let shouldDebounce = hasValue && shouldResolve

        let newUpdatingTask = Task { [weak self] in
            do {
                if shouldDebounce {
                    try await Task.sleep(for: .seconds(1))
                    try Task.checkCancellation()
                }

                try await self?.interactor.update(destination: destination.string, source: destination.source)
            } catch {
                await MainActor.run { [weak self] in
                    if self?.updatingDestinationString == destination.string {
                        self?.updatingDestinationString = nil
                    }
                }
                throw error
            }
        }

        updatingTask?.cancel()
        updatingTask = newUpdatingTask
        updatingDestinationString = destination.string

        return newUpdatingTask
    }
}

extension SendDestinationViewModel {
    enum DestinationAddressSectionType: Identifiable {
        case destinationAddress(SendDestinationAddressViewModel)
        case destinationResolvedAddress(String)

        var id: String {
            switch self {
            case .destinationAddress(let viewModel): String(describing: viewModel.id)
            case .destinationResolvedAddress(let address): address
            }
        }
    }
}

// MARK: - SendDestinationAddressViewRoutable

private extension SendDestinationViewModel {
    enum Constants {
        static let addressBookContactsLimit = 3
        static let contactsFilterDebounce = 300
        static let destinationErrorDisplayDelay = 400
    }
}

// MARK: - AddressBooksSelectionOutput

extension SendDestinationViewModel: AddressBooksSelectionOutput {
    func addressBooksDidSelect(_ group: AddressBookContactAddressGroup, of contact: AddressBookContact) {
        applyAddressBookAddress(group, from: contact)
    }
}

// MARK: - ChooseAddressOutput

extension SendDestinationViewModel: ChooseAddressOutput {
    func chooseAddressDidSelect(_ group: AddressBookContactAddressGroup, of contact: AddressBookContact) {
        applyAddressBookAddress(group, from: contact)
    }
}

extension SendDestinationViewModel: SendDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        let binding = Binding<String>(get: { "" }, set: { [weak self] value in
            self?.sendQRCodeService.qrCodeDidScanned(value: value)
        })

        analyticsLogger.logQRScannerOpened()
        router?.openQRScanner(with: binding, networkName: networkName)
    }
}

// MARK: - SendDestinationExternalUpdatableViewModel

extension SendDestinationViewModel: SendDestinationExternalUpdatableViewModel {
    func externalUpdate(address: SendDestination) {
        destinationAddressViewModel.update(address: .init(string: address.value.transactionAddress, source: address.source))
        destinationResolvedAddress = address.value.showableResolved
    }

    func externalUpdate(additionalField: SendDestinationAdditionalField) {
        switch additionalField {
        case .notSupported, .empty:
            additionalFieldViewModel?.update(text: "")
        case .filled(_, let value, _):
            additionalFieldViewModel?.update(text: value)
        }
    }
}

private extension SendDestinationSuggested.DestinationType {
    var source: Analytics.DestinationAddressSource {
        switch self {
        case .otherWallet:
            return .myWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}
