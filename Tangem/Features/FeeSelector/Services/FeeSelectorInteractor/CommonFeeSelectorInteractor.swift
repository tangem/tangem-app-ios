//
//  CommonFeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class CommonFeeSelectorInteractor {
    private weak var input: (any FeeSelectorInteractorInput)?
    private weak var output: (any FeeSelectorOutput)?

    private let feesProvider: any TokenFeeProvider

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        feesProvider: any TokenFeeProvider,
    ) {
        self.input = input
        self.output = output
        self.feesProvider = feesProvider
    }
}

// MARK: - FeeSelectorInteractor

extension CommonFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedFee: TokenFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        input?.selectedFeePublisher.eraseToAnyPublisher() ?? .just(output: .none)
    }

    var fees: [TokenFee] {
        feesProvider.fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesProvider.feesPublisher
    }

    var selectedFeeTokenItem: TokenFeeItem? {
        selectedFee?.tokenItem
    }

    var selectedFeeTokenItemPublisher: AnyPublisher<TokenFeeItem?, Never> {
        selectedFeePublisher.map { $0?.tokenItem }.eraseToAnyPublisher()
    }

    var feeTokenItems: [TokenItem] {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.tokenItems ?? []
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.tokenItemsPublisher ?? .just(output: [])
    }

    func userDidSelect(feeTokenItem: TokenItem) {
        (feesProvider as? UpdatableSimpleTokenFeeProvider)?.userDidSelectTokenItem(feeTokenItem)
    }

    func userDidSelect(selectedFee: TokenFee) {
        output?.userDidSelect(selectedFee: selectedFee)
    }
}

// MARK: - Private

private extension CommonFeeSelectorInteractor {}

protocol MultiProvidersFeeSelectorInteractorInput: AnyObject {
    var selectedFee: TokenFee? { get }
    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> { get }
}

struct RequiredElementArray<Element> {
    let element: Element
    let array: [Element]
}

final class MultiProvidersFeeSelectorInteractor {
    private weak var input: (any FeeSelectorInteractorInput)?
    private weak var output: (any FeeSelectorOutput)?

    private let feeProviders: [any GeneralFeeProvider]
    private let selectedFeeItemSubject: CurrentValueSubject<TokenFeeItem, Never>

    var selectedFeeProvider: (any GeneralFeeProvider)? {
        feeProviders.first { $0.feeItem == selectedFeeItemSubject.value }
    }

    var selectedFeeProviderPublisher: AnyPublisher<(any GeneralFeeProvider)?, Never> {
        selectedFeeItemSubject
            .withWeakCaptureOf(self)
            .map { interactor, selectedFeeItem in
                interactor.feeProviders.first { $0.feeItem == selectedFeeItem }
            }
            .eraseToAnyPublisher()
    }

    init(
        input: any FeeSelectorInteractorInput,
        output: any FeeSelectorOutput,
        feeProviders: [any GeneralFeeProvider],
        initialSelectedFeeItem: TokenFeeItem,
    ) {
        self.input = input
        self.output = output
        self.feeProviders = feeProviders

        selectedFeeItemSubject = .init(initialSelectedFeeItem)
    }
}

// MARK: - FeeSelectorInteractor

extension MultiProvidersFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedFee: TokenFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        input?.selectedFeePublisher.eraseToAnyPublisher() ?? .just(output: .none)
    }

    var fees: [TokenFee] {
        selectedFeeProvider?.fees ?? []
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        selectedFeeProviderPublisher
            .flatMapLatest { $0?.feesPublisher ?? .just(output: []) }
            .eraseToAnyPublisher()
    }

    var selectedFeeTokenItem: TokenFeeItem? {
        selectedFee?.tokenItem
    }

    var selectedFeeTokenItemPublisher: AnyPublisher<TokenFeeItem?, Never> {
        selectedFeePublisher.map { $0?.tokenItem }.eraseToAnyPublisher()
    }

    var feeTokenItems: [TokenItem] {
        feeProviders.map { $0.feeItem }
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        .just(output: feeProviders.map { $0.feeItem })
    }

    func userDidSelect(feeTokenItem: TokenItem) {
        selectedFeeItemSubject.send(feeTokenItem)
    }

    func userDidSelect(selectedFee: TokenFee) {
        output?.userDidSelect(selectedFee: selectedFee)
    }
}

// MARK: - FeeSelectorCustomFeeAvailabilityProvider

extension MultiProvidersFeeSelectorInteractor: FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool {
        (selectedFeeProvider as? FeeSelectorCustomFeeAvailabilityProvider)?.customFeeIsValid ?? false
    }

    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> {
        (selectedFeeProvider as? FeeSelectorCustomFeeAvailabilityProvider)?.customFeeIsValidPublisher ?? .just(output: false)
    }

    func captureCustomFeeFieldsValue() {
        (selectedFeeProvider as? FeeSelectorCustomFeeAvailabilityProvider)?.captureCustomFeeFieldsValue()
    }

    func resetCustomFeeFieldsValue() {
        (selectedFeeProvider as? FeeSelectorCustomFeeAvailabilityProvider)?.resetCustomFeeFieldsValue()
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension MultiProvidersFeeSelectorInteractor: FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        (selectedFeeProvider as? FeeSelectorCustomFeeFieldsBuilder)?.buildCustomFeeFields() ?? []
    }
}

// MARK: - Private

private extension MultiProvidersFeeSelectorInteractor {}
