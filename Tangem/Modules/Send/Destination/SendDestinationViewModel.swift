//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendDestinationViewModelInput {
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var destinationAdditionalFieldTextPublisher: AnyPublisher<String, Never> { get }

    var destinationError: AnyPublisher<Error?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { get }

    var networkName: String { get }
    var blockchainNetwork: BlockchainNetwork { get }
    var walletPublicKey: Wallet.PublicKey { get }

    var additionalField: SendAdditionalFields? { get }

    var currencySymbol: String { get }
    var walletAddresses: [String] { get }

    var transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never> { get }
}

protocol SendDestinationViewDelegate: AnyObject {
    func didEnterAddress(_ address: String)
    func didEnterAdditionalField(_ additionalField: String)

    func didSelectSuggestedDestination(_ destination: SendSuggestedDestination)
}

class SendDestinationViewModel: ObservableObject {
    var addressViewModel: SendDestinationInputViewModel?
    var additionalFieldViewModel: SendDestinationInputViewModel?
    var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?

    @Published var destinationErrorText: String?
    @Published var destinationAdditionalFieldErrorText: String?

    weak var delegate: SendDestinationViewDelegate?

    private let transactionHistoryMapper: TransactionHistoryMapper
    private let suggestedWallets: [SendSuggestedDestinationWallet]

    private var bag: Set<AnyCancellable> = []

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    // MARK: - Methods

    init(input: SendDestinationViewModelInput) {
        transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: input.currencySymbol,
            walletAddresses: input.walletAddresses,
            showSign: false
        )

        suggestedWallets = Self.userWalletRepository
            .models
            .compactMap { userWalletModel in
                let walletModels = userWalletModel.walletModelsManager.walletModels
                let walletModel = walletModels.first { walletModel in
                    walletModel.blockchainNetwork == input.blockchainNetwork &&
                        walletModel.wallet.publicKey != input.walletPublicKey
                }
                guard let walletModel else { return nil }

                return SendSuggestedDestinationWallet(
                    name: userWalletModel.userWallet.name,
                    address: walletModel.defaultAddress
                )
            }

        addressViewModel = SendDestinationInputViewModel(
            name: Localization.sendRecipient,
            input: input.destinationTextPublisher,
            showAddressIcon: true,
            placeholder: Localization.sendEnterAddressField,
            description: Localization.sendRecipientAddressFooter(input.networkName),
            errorText: input.destinationError
        ) { [weak self] in
            self?.delegate?.didEnterAddress($0)
        }

        if let additionalField = input.additionalField,
           let name = additionalField.name {
            additionalFieldViewModel = SendDestinationInputViewModel(
                name: name,
                input: input.destinationAdditionalFieldTextPublisher,
                showAddressIcon: false,
                placeholder: Localization.sendOptionalField,
                description: Localization.sendRecipientMemoFooter,
                errorText: input.destinationAdditionalFieldError
            ) { [weak self] in
                self?.delegate?.didEnterAdditionalField($0)
            }
        }

        bind(from: input)
    }

    private func bind(from input: SendDestinationViewModelInput) {
        input
            .destinationError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationErrorText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .destinationAdditionalFieldError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationAdditionalFieldErrorText, on: self, ownership: .weak)
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
                    self?.delegate?.didSelectSuggestedDestination(destination)
                }
            }
            .store(in: &bag)
    }
}
