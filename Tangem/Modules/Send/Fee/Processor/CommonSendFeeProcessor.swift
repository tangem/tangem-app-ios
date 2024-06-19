//
//  CommonSendFeeProcessor.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonSendFeeProcessor {
    private let provider: SendFeeProvider
    private var customFeeService: CustomFeeService?

    private let _cryptoAmount: CurrentValueSubject<Amount?, Never> = .init(.none)
    private let _destination: CurrentValueSubject<String?, Never> = .init(.none)
    private let _fees: CurrentValueSubject<[SendFee], Never> = .init([])
    private let _customFee: CurrentValueSubject<Fee?, Never> = .init(.none)

    private let defaultFeeOptions: [FeeOption]
    private var feeOptions: [FeeOption] {
        var options = defaultFeeOptions
        if supportCustomFee {
            options.append(.custom)
        }
        return options
    }

    private var supportCustomFee: Bool {
        customFeeService != nil
    }

    private var bag: Set<AnyCancellable> = []

    init(
        provider: SendFeeProvider,
        defaultFeeOptions: [FeeOption],
        customFeeServiceFactory: CustomFeeServiceFactory
    ) {
        self.provider = provider
        self.defaultFeeOptions = defaultFeeOptions

        customFeeService = customFeeServiceFactory.makeService(input: self, output: self)
        bind()
    }

    func bind() {
        _fees
            .compactMap { $0.first(where: { $0.option == .market })?.value.value }
            .withWeakCaptureOf(self)
            // Only once
            .first()
            .sink { processor, fee in
                processor.customFeeService?.initialSetupCustomFee(fee)
            }
            .store(in: &bag)
    }
}

// MARK: - CustomFeeServiceInput

extension CommonSendFeeProcessor: CustomFeeServiceInput {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> {
        _cryptoAmount.compactMap { $0 }.eraseToAnyPublisher()
    }

    var destinationPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - CustomFeeServiceOutput

extension CommonSendFeeProcessor: CustomFeeServiceOutput {
    func customFeeDidChanged(_ customFee: Fee?) {
        _customFee.send(customFee)
    }
}

// MARK: - SendFeeProcessor

extension CommonSendFeeProcessor: SendFeeProcessor {
    func setup(input: SendFeeProcessorInput) {
        input.cryptoAmountPublisher
            .withWeakCaptureOf(self)
            .sink { processor, amount in
                processor._cryptoAmount.send(amount)
            }
            .store(in: &bag)

        input.destinationPublisher
            .withWeakCaptureOf(self)
            .sink { processor, destination in
                processor._destination.send(destination)
            }
            .store(in: &bag)
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value,
              let destination = _destination.value else {
            assertionFailure("SendFeeProcessor is not ready to update fees")
            return
        }

        provider
            .getFee(amount: amount, destination: destination)
            .sink(receiveCompletion: { [weak self] completion in
                guard case .failure(let error) = completion else {
                    return
                }

                self?.update(fees: .failedToLoad(error: error))
            }, receiveValue: { [weak self] fees in
                self?.update(fees: .loaded(fees))
            })
            .store(in: &bag)
    }

    func feesPublisher() -> AnyPublisher<[SendFee], Never> {
        _fees.dropFirst().eraseToAnyPublisher()
    }

    func customFeePublisher() -> AnyPublisher<SendFee, Never> {
        _customFee
            .compactMap { $0.map { SendFee(option: .custom, value: .loaded($0)) } }
            .eraseToAnyPublisher()
    }

    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel] {
        customFeeService?.inputFieldModels() ?? []
    }
}

// MARK: - Private

private extension CommonSendFeeProcessor {
    func update(fees value: LoadingValue<[Fee]>) {
        switch value {
        case .loading:
            _fees.send(feeOptions.map { SendFee(option: $0, value: .loading) })
        case .loaded(let fees):
            _fees.send(mapToFees(fees: fees))
        case .failedToLoad(let error):
            _fees.send(feeOptions.map { SendFee(option: $0, value: .failedToLoad(error: error)) })
        }
    }

    func mapToFees(fees: [Fee]) -> [SendFee] {
        var defaultOptions = mapToDefaultFees(fees: fees)

        if supportCustomFee {
            var customFee = _customFee.value
            if customFee == nil {
                customFee = defaultOptions.first(where: { $0.option == .market })?.value.value
            }

            if let customFee {
                defaultOptions.append(SendFee(option: .custom, value: .loaded(customFee)))
            }
        }

        return defaultOptions
    }

    func mapToDefaultFees(fees: [Fee]) -> [SendFee] {
        switch fees.count {
        case 1:
            return [SendFee(option: .market, value: .loaded(fees[1]))]
        case 3:
            return [
                SendFee(option: .slow, value: .loaded(fees[0])),
                SendFee(option: .market, value: .loaded(fees[1])),
                SendFee(option: .fast, value: .loaded(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}
