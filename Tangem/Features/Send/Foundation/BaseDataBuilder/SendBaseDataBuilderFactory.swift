//
//  SendDataBuilderFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendBaseDataBuilderFactory {
    let walletModel: any WalletModel
    let userWalletInfo: UserWalletInfo

    func makeSendBaseDataBuilder(
        input: SendBaseDataBuilderInput,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    ) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )
    }

    func makeStakingBaseDataBuilder(
        input: StakingBaseDataBuilderInput
    ) -> StakingBaseDataBuilder {
        CommonStakingBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider
        )
    }

    func makeOnrampBaseDataBuilder(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) -> OnrampBaseDataBuilder {
        CommonOnrampBaseDataBuilder(
            config: userWalletInfo.config,
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            providersBuilder: providersBuilder,
            paymentMethodsBuilder: paymentMethodsBuilder,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )
    }
}
