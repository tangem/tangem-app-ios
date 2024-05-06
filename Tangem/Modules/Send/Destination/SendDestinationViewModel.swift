//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendDestinationViewModelInput {
    var networkName: String { get }
    var blockchainNetwork: BlockchainNetwork { get }

    var additionalFieldType: SendAdditionalFields? { get }
    var additionalFieldEmbeddedInAddress: AnyPublisher<Bool, Never> { get }

    var currencySymbol: String { get }
    var walletAddresses: [String] { get }

    var transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never> { get }

    func setDestination(_ address: SendAddress)
    func setTransactionParameters(transactionParameters: TransactionParams?)
}

class SendDestinationViewModel: ObservableObject {
    var isValidatingDestination: AnyPublisher<Bool, Never> { addressService.validationInProgressPublisher }

    var addressViewModel: SendDestinationTextViewModel?
    var additionalFieldViewModel: SendDestinationTextViewModel?

    var isValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(validatedDestination, _destinationAdditionalFieldError)
            .map {
                $0?.value != nil && $1 == nil
            }
            .eraseToAnyPublisher()
    }

    @Published var userInputDisabled = false
    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published var showSuggestedDestinations = true

    var didProperlyDisappear: Bool = false

    private let input: SendDestinationViewModelInput
    private let walletInfo: SendWalletInfo
    private let addressTextViewHeightModel: AddressTextViewHeightModel
    private let transactionHistoryMapper: TransactionHistoryMapper
    private let addressService: SendAddressService
    private let destinationValidator: SendDestinationValidator
    private let suggestedWallets: [SendSuggestedDestinationWallet]

    private var destinationTextPublisher = CurrentValueSubject<String, Never>("")
    private var destinationAdditionalFieldTextPublisher = CurrentValueSubject<String, Never>("")

    private let _destinationError = CurrentValueSubject<Error?, Never>(nil)
    private let _destinationAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)

    private let validatedDestination = CurrentValueSubject<SendAddress?, Never>(nil)
    private var destinationResolutionRequest: Task<Void, Error>?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    // MARK: - Methods

    init(input: SendDestinationViewModelInput, addressService: SendAddressService, addressTextViewHeightModel: AddressTextViewHeightModel, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        self.addressService = addressService
        destinationValidator = SendDestinationValidator(addressService: addressService)
        self.addressTextViewHeightModel = addressTextViewHeightModel

        transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: input.currencySymbol,
            walletAddresses: input.walletAddresses,
            showSign: false
        )

        let blockchain = input.blockchainNetwork.blockchain
        let currentUserWalletId = Self.userWalletRepository.selectedModel?.userWalletId

        suggestedWallets = Self.userWalletRepository
            .models
            .compactMap { userWalletModel in
                if userWalletModel.userWalletId == currentUserWalletId {
                    return nil
                }

                let walletModels = userWalletModel.walletModelsManager.walletModels
                let walletModel = walletModels.first { walletModel in
                    // Disregarding the difference between testnet and mainnet blockchains
                    // See https://github.com/tangem/tangem-app-ios/pull/3079#discussion_r1553709671
                    return walletModel.blockchainNetwork.blockchain.networkId == blockchain.networkId &&
                        !walletModel.isCustom
                }

                guard let walletModel else { return nil }

                return SendSuggestedDestinationWallet(
                    name: userWalletModel.name,
                    address: walletModel.defaultAddress
                )
            }

        addressViewModel = SendDestinationTextViewModel(
            style: .address(networkName: input.networkName),
            input: destinationTextPublisher.eraseToAnyPublisher(),
            isValidating: isValidatingDestination,
            isDisabled: .just(output: false),
            addressTextViewHeightModel: addressTextViewHeightModel,
            errorText: _destinationError.eraseToAnyPublisher()
        ) { [weak self] in
            self?.setAddress(SendAddress(value: $0, source: .textField))
        } didPasteDestination: { [weak self] in
            self?.setAddress(SendAddress(value: $0, source: .pasteButton))
        }

        if let additionalFieldType = input.additionalFieldType,
           let name = additionalFieldType.name {
            additionalFieldViewModel = SendDestinationTextViewModel(
                style: .additionalField(name: name),
                input: destinationAdditionalFieldTextPublisher.eraseToAnyPublisher(),
                isValidating: .just(output: false),
                isDisabled: input.additionalFieldEmbeddedInAddress,
                addressTextViewHeightModel: .init(),
                errorText: _destinationAdditionalFieldError.eraseToAnyPublisher()
            ) { [weak self] in
//                self?.input.setDestinationAdditionalField($0)
                self?.setAdditionalField($0)
            } didPasteDestination: { [weak self] in
//                self?.input.setDestinationAdditionalField($0)
                self?.setAdditionalField($0)
            }
        }

        bind()
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .address])
        } else {
            Analytics.log(.sendAddressScreenOpened)
        }
    }

    func setUserInputDisabled(_ userInputDisabled: Bool) {
        self.userInputDisabled = userInputDisabled
    }

    func setAddress(_ sendAddress: SendAddress) {
        guard destinationTextPublisher.value != sendAddress.value else { return }

        destinationTextPublisher.send(sendAddress.value ?? "")

        destinationResolutionRequest?.cancel()

        validatedDestination.send(nil)

        destinationResolutionRequest = runTask(in: self) { `self` in
            let result: SendAddress
            let error: Error?
            do {
                let validatedAddress = try await self.addressService.validate(address: sendAddress.value ?? "")
                result = SendAddress(value: validatedAddress, source: sendAddress.source)

                guard !Task.isCancelled else { return }

                error = nil
            } catch let addressError {
                result = SendAddress(value: nil, source: sendAddress.source)
                error = addressError
            }

            await runOnMain {
                self.validatedDestination.send(result)
                self._destinationError.send(error)
            }
        }
    }

    func setAdditionalField(_ additionalField: String) {
        let error: Error?
        let transactionParameters: TransactionParams?
        do {
            let parametersBuilder = SendTransactionParametersBuilder(blockchain: walletInfo.blockchain)
            transactionParameters = try parametersBuilder.transactionParameters(from: additionalField)
            error = nil
        } catch let transactionParameterError {
            transactionParameters = nil
            error = transactionParameterError
        }

        input.setTransactionParameters(transactionParameters: transactionParameters)
        _destinationAdditionalFieldError.send(error)
    }

    private func bind() {
        validatedDestination
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] destinationValid in
                withAnimation(SendView.Constants.defaultAnimation) {
                    self?.showSuggestedDestinations = !destinationValid
                }
            }
            .store(in: &bag)

        input
            .transactionHistoryPublisher
            .compactMap { [weak self] state -> [SendSuggestedDestinationTransactionRecord] in
                guard
                    let self,
                    case .loaded(let records) = state
                else {
                    return []
                }

                return records.compactMap { record in
                    self.transactionHistoryMapper.mapSuggestedRecord(record)
                }
            }
            .sink { [weak self] recentTransactions in
                guard let self else { return }

                if suggestedWallets.isEmpty, recentTransactions.isEmpty {
                    suggestedDestinationViewModel = nil
                    return
                }

                suggestedDestinationViewModel = SendSuggestedDestinationViewModel(
                    wallets: suggestedWallets,
                    recentTransactions: recentTransactions
                ) { [weak self] destination in
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)

                    // TODO: different source ❌
                    self?.setAddress(SendAddress(value: destination.address, source: destination.type.source))
                    if let additionalField = destination.additionalField {
                        self?.setAdditionalField(additionalField)
                    }
                }
            }
            .store(in: &bag)
    }
}

extension SendDestinationViewModel: SendStepSaveable {
    func save() {
        guard
            let destination = validatedDestination.value
        else {
            return
        }
        input.setDestination(destination)
    }
}

extension SendDestinationViewModel: AuxiliaryViewAnimatable {}

private extension SendSuggestedDestination.`Type` {
    var source: Analytics.DestinationAddressSource {
        switch self {
        case .otherWallet:
            return .myWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}

// TODO: QR Code ❌
