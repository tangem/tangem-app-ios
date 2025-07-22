//
//  SendNewDestinationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemFoundation
import SwiftUI

class SendNewDestinationViewModel: ObservableObject, Identifiable {
    @Published var destinationAddressViewModel: SendNewDestinationAddressViewModel
    @Published var additionalFieldViewModel: SendNewDestinationAdditionalFieldViewModel?

    @Published var shouldShowSuggestedDestination: Bool = true
    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?

    @Published var networkName: String = ""

    // MARK: - Private

    private let interactor: SendNewDestinationInteractor
    private let sendQRCodeService: SendQRCodeService
    private let analyticsLogger: SendDestinationAnalyticsLogger
    private weak var router: SendDestinationRoutable?

    private var allFieldsIsValidSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    weak var stepRouter: SendDestinationStepRoutable?

    // MARK: - Methods

    init(
        interactor: SendNewDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable
    ) {
        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.analyticsLogger = analyticsLogger
        self.router = router

        destinationAddressViewModel = SendNewDestinationAddressViewModel(
            textViewModel: .init(),
            sendAddress: .init(value: "", source: .textField)
        )

        destinationAddressViewModel.router = self
        bind()
    }

    func onAppear() {
        interactor.preloadTransactionsHistoryIfNeeded()
    }

    private func updateView(tokenItem: TokenItem) {
        networkName = tokenItem.networkName

        additionalFieldViewModel = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain).map { additionalFieldType in
            .init(title: additionalFieldType.name)
        }
    }

    private func bind() {
        // MARK: - Token

        interactor.tokenItemPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { $0.updateView(tokenItem: $1) }
            .store(in: &bag)

        // MARK: - Destination

        destinationAddressViewModel.addressPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, destination in
                viewModel.interactor.update(destination: destination.value, source: destination.source)
            }
            .store(in: &bag)

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

        // MARK: - Transaction History

        Publishers.CombineLatest(interactor.transactionHistoryPublisher, interactor.suggestedWalletsPublisher)
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
                viewModel.destinationAddressViewModel.update(address: .init(value: address, source: .qrCode))
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

        interactor.destinationAdditionalFieldError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.additionalFieldViewModel?.update(error: error)
            }
            .store(in: &bag)

        additionalFieldViewModel?.textPublisher()
            .dropFirst()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, field in
                viewModel.interactor.update(additionalField: field)
            }
            .store(in: &bag)
    }

    private func setupSuggestedDestination(recentTransactions: [SendSuggestedDestinationTransactionRecord], suggestedWallets: [SendSuggestedDestinationWallet]) {
        let hasSuggestions = !suggestedWallets.isEmpty || !recentTransactions.isEmpty

        guard hasSuggestions else {
            suggestedDestinationViewModel = nil
            return
        }

        suggestedDestinationViewModel = SendSuggestedDestinationViewModel(
            wallets: suggestedWallets,
            recentTransactions: recentTransactions
        ) { [weak self] destination in
            self?.userDidTapSuggestedDestination(destination)
        }
    }

    private func userDidTapSuggestedDestination(_ destination: SendSuggestedDestination) {
        FeedbackGenerator.success()
        destinationAddressViewModel.update(address: .init(value: destination.address, source: .qrCode))

        if let additionalField = destination.additionalField {
            additionalFieldViewModel?.update(text: additionalField)
        }

        allFieldsIsValidSubscription = interactor.allFieldsIsValid
            // Drop initial value
            .dropFirst()
            .combineLatest(destinationAddressViewModel.$sendAddress)
            // Take only one with this address
            .first { $1.value == destination.address }
            // Give some time to update UI fields
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            // Move to next steps only when all is valid
            .filter { $0.0 }
            .withWeakCaptureOf(self)
            .sink {
                $0.0.allFieldsIsValidSubscription?.cancel()
                $0.0.interactor.saveChanges()
                $0.0.stepRouter?.destinationStepFulfilled()
            }
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewDestinationViewModel: SendNewDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        let binding = Binding<String>(get: { "" }, set: { [weak self] value in
            self?.sendQRCodeService.qrCodeDidScanned(value: value)
        })

        analyticsLogger.logQRScannerOpened()
        router?.openQRScanner(with: binding, networkName: networkName)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewDestinationViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

private extension SendSuggestedDestination.DestinationType {
    var source: Analytics.DestinationAddressSource {
        switch self {
        case .otherWallet:
            return .myWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}
