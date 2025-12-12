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

protocol SendBaseDataBuilder: SendFeeCurrencyProviderDataBuilder {
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
    func makeMailData(transactionData: Data, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
    func makeSendReceiveTokensList() -> SendReceiveTokensListBuilder
}

protocol StakingBaseDataBuilder: SendFeeCurrencyProviderDataBuilder {
    func makeMailData(stakingRequestError error: UniversalError) throws -> (dataCollector: EmailDataCollector, recipient: String)
    func makeMailData(action: StakingTransactionAction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
    func makeDataForExpressApproveViewModel() throws -> (settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput)
}

protocol OnrampBaseDataBuilder: SendGenericBaseDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampCountrySelectorView() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampRedirecting() -> OnrampRedirectingBuilder
    func demoAlertMessage() -> String?
}

protocol SendFeeCurrencyProviderDataBuilder: SendGenericBaseDataBuilder {
    func makeFeeCurrencyData() -> FeeCurrencyNavigatingDismissOption
}

protocol SendGenericBaseDataBuilder {
    func feeCurrencyProvider() throws -> SendFeeCurrencyProviderDataBuilder

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
