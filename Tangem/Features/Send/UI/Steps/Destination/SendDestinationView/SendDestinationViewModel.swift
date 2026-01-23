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
    var destinationAddressSectionType: [DestinationAddressSectionType] {
        var section: [DestinationAddressSectionType] = [.destinationAddress(destinationAddressViewModel)]
        if let destinationResolvedAddress {
            section.append(.destinationResolvedAddress(destinationResolvedAddress))
        }
        return section
    }

    @Published var additionalFieldViewModel: SendDestinationAdditionalFieldViewModel?

    @Published var shouldShowSuggestedDestination: Bool = true
    @Published var suggestedDestinationViewModel: SendDestinationSuggestedViewModel?

    @Published var networkName: String = ""

    @Published private var destinationAddressViewModel: SendDestinationAddressViewModel
    @Published private var destinationResolvedAddress: String?

    // MARK: - Private

    private let interactor: SendDestinationInteractor
    private let sendQRCodeService: SendQRCodeService
    private let analyticsLogger: SendDestinationAnalyticsLogger
    private weak var router: SendDestinationRoutable?
    private weak var destinationAccountOutput: SendDestinationAccountOutput?

    private var allFieldsIsValidSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    weak var stepRouter: SendDestinationStepRoutable?

    // MARK: - Methods

    init(
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable,
        destinationAccountOutput: SendDestinationAccountOutput
    ) {
        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.analyticsLogger = analyticsLogger
        self.router = router
        self.destinationAccountOutput = destinationAccountOutput

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )

        destinationAddressViewModel.router = self
        bind()
    }

    func onAppear() {
        interactor.preloadTransactionsHistoryIfNeeded()
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
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.updateView(tokenItem: $1) }
            .store(in: &bag)

        // MARK: - Destination

        destinationAddressViewModel
            .addressPublisher()
            .dropFirst()
            .debounce(for: .seconds(1)) { [interactor] in
                !$0.string.isEmpty && interactor.willResolve(address: $0.string)
            }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, destination in
                viewModel.interactor.update(destination: destination.string, source: destination.source)
            }
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

        interactor.destinationError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.destinationAddressViewModel.update(error: error)
            }
            .store(in: &bag)

        interactor.ignoreDestinationClear
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, ignore in
                viewModel.destinationAddressViewModel.update(shouldIgnoreClearButton: ignore)
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

    private func userDidTapSuggestedDestination(_ destination: SendDestinationSuggested) {
        FeedbackGenerator.success()

        // Set destination account via SendModel, which forwards to analytics logger
        destinationAccountOutput?.setDestinationAccountInfo(
            tokenHeader: destination.tokenHeader,
            analyticsProvider: destination.accountModelAnalyticsProvider
        )

        destinationAddressViewModel.update(address: .init(
            string: destination.address,
            source: destination.type.source
        ))

        if let additionalField = destination.additionalField {
            additionalFieldViewModel?.update(text: additionalField)
        }

        allFieldsIsValidSubscription = interactor.allFieldsIsValid
            // Drop initial value
            .dropFirst()
            .combineLatest(destinationAddressViewModel.addressPublisher())
            // Take only one with this address
            .first { $1.string == destination.address }
            // Give some time to update UI fields
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            // Move to next steps only when all is valid
            .filter { $0.0 }
            .withWeakCaptureOf(self)
            .sink {
                $0.0.allFieldsIsValidSubscription?.cancel()
                $0.0.stepRouter?.destinationStepFulfilled()
            }
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
        guard case .filled(_, let value, _) = additionalField else {
            return
        }

        additionalFieldViewModel?.update(text: value)
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
