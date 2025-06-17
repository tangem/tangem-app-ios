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
    @Published var destinationAddressViewModel: SendNewDestinationAddressViewModel?
    @Published var additionalFieldViewModel: SendNewDestinationAdditionalFieldViewModel?

    @Published var shouldShowSuggestedDestination: Bool = true
    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?

    let addressDescription: String
    let additionalFieldDescription: String
    let addressTextViewHeightModel: AddressTextViewHeightModel

    // MARK: - Private

    private let settings: Settings
    private let interactor: SendDestinationInteractor
    private let sendQRCodeService: SendQRCodeService
    private weak var router: SendDestinationRoutable?

    private let suggestedWallets: [SendSuggestedDestinationWallet]
    private var bag: Set<AnyCancellable> = []

    weak var stepRouter: SendDestinationStepRoutable?

    // MARK: - Methods

    init(
        settings: Settings,
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) {
        self.settings = settings
        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.router = router

        addressDescription = Localization.sendRecipientAddressFooter(settings.networkName)
        additionalFieldDescription = Localization.sendRecipientMemoFooter

        suggestedWallets = settings.suggestedWallets.map { wallet in
            SendSuggestedDestinationWallet(name: wallet.name, address: wallet.address)
        }

        setupView()
        bind()
    }

    func onAppear() {}

    private func setupView() {
        destinationAddressViewModel = SendNewDestinationAddressViewModel(
            textViewModel: addressTextViewHeightModel,
            sendAddress: .init(value: "", source: .textField),
            router: self
        )

        additionalFieldViewModel = settings.additionalFieldType.map { additionalFieldType in
            .init(title: additionalFieldType.name)
        }
    }

    private func bind() {
        // MARK: - Destination

        destinationAddressViewModel?.addressPublisher()
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
                viewModel.destinationAddressViewModel?.update(isValidating: isValidating)
            }
            .store(in: &bag)

        interactor.destinationError
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.destinationAddressViewModel?.update(error: error)
            }
            .store(in: &bag)

        // MARK: - Transaction History

        interactor.transactionHistoryPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, recentTransactions in
                viewModel.setupSuggestedDestination(recentTransactions: recentTransactions)
            }
            .store(in: &bag)

        interactor.destinationValid
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, destinationValid in
                let text = viewModel.destinationAddressViewModel?.text.value ?? ""
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
                viewModel.destinationAddressViewModel?.update(address: .init(value: address, source: .qrCode))
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

    private func setupSuggestedDestination(recentTransactions: [SendSuggestedDestinationTransactionRecord]) {
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
        destinationAddressViewModel?.update(address: .init(value: destination.address, source: .qrCode))

        if let additionalField = destination.additionalField {
            additionalFieldViewModel?.update(text: additionalField)
        }

        guard !interactor.hasError else {
            return
        }

        // Give some time to update UI fields
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.stepRouter?.destinationStepFulfilled()
        }
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewDestinationViewModel: SendNewDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        let binding = Binding<String>(get: { "" }, set: { [weak self] value in
            self?.sendQRCodeService.qrCodeDidScanned(value: value)
        })

        router?.openQRScanner(with: binding, networkName: settings.networkName)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewDestinationViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendNewDestinationViewModel {
    struct Settings {
        typealias SuggestedWallet = (name: String, address: String)

        let networkName: String
        let additionalFieldType: SendDestinationAdditionalFieldType?
        let suggestedWallets: [SuggestedWallet]
    }
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
