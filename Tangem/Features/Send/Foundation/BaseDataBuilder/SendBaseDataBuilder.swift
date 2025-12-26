//
//  SendBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemStaking
import TangemExpress
import TangemFoundation

typealias MailData = (dataCollector: EmailDataCollector, recipient: String)

protocol SendBaseDataBuilder: SendGenericBaseDataBuilder,
    SendApproveViewModelInputDataBuilder,
    SendFeeCurrencyProviderDataBuilder {
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> MailData
    func makeMailData(transactionData: Data, error: SendTxError) -> MailData
    func makeSendReceiveTokensList() -> SendReceiveTokensListBuilder
}

protocol StakingBaseDataBuilder: SendGenericBaseDataBuilder,
    SendApproveViewModelInputDataBuilder,
    SendFeeCurrencyProviderDataBuilder {
    func makeMailData(stakingRequestError error: UniversalError) throws -> MailData
    func makeMailData(action: StakingTransactionAction, error: SendTxError) -> MailData
}

protocol OnrampBaseDataBuilder: SendGenericBaseDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampCountrySelectorView() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampRedirecting() -> OnrampRedirectingBuilder
    func demoAlertMessage() -> String?
}

protocol SendFeeCurrencyProviderDataBuilder {
    func makeFeeCurrencyData() -> FeeCurrencyNavigatingDismissOption
}

protocol SendApproveViewModelInputDataBuilder: SendGenericBaseDataBuilder {
    func makeExpressApproveViewModelInput() async throws -> ExpressApproveViewModel.Input
}

protocol SendGenericBaseDataBuilder {
    func feeCurrencyProvider() throws -> SendFeeCurrencyProviderDataBuilder
    func approveViewModelProvider() throws -> SendApproveViewModelInputDataBuilder

    func sendBuilder() throws -> SendBaseDataBuilder
    func stakingBuilder() throws -> StakingBaseDataBuilder
    func onrampBuilder() throws -> OnrampBaseDataBuilder
}

extension SendGenericBaseDataBuilder {
    func feeCurrencyProvider() throws -> SendFeeCurrencyProviderDataBuilder {
        guard let builder = self as? SendFeeCurrencyProviderDataBuilder else {
            throw SendBaseDataBuilderError.notFound("SendFeeCurrencyProviderDataBuilder")
        }
        return builder
    }

    func approveViewModelProvider() throws -> SendApproveViewModelInputDataBuilder {
        guard let builder = self as? SendApproveViewModelInputDataBuilder else {
            throw SendBaseDataBuilderError.notFound("SendApproveViewModelInputDataBuilder")
        }
        return builder
    }

    func sendBuilder() throws -> SendBaseDataBuilder {
        guard let builder = self as? SendBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("SendBaseDataBuilder")
        }
        return builder
    }

    func stakingBuilder() throws -> StakingBaseDataBuilder {
        guard let builder = self as? StakingBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("StakingBaseDataBuilder")
        }
        return builder
    }

    func onrampBuilder() throws -> OnrampBaseDataBuilder {
        guard let builder = self as? OnrampBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("OnrampBaseDataBuilder")
        }
        return builder
    }
}

enum SendBaseDataBuilderError: LocalizedError {
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let string):
            "\(string) not found"
        }
    }
}
