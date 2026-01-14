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
        baseDataInput: any SendBaseDataBuilderInput,
        approveDataInput: any SendApproveDataBuilderInput,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    ) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(
            baseDataInput: baseDataInput,
            approveDataInput: approveDataInput,
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }

    func makeStakingBaseDataBuilder(
        input: StakingBaseDataBuilderInput
    ) -> StakingBaseDataBuilder {
        CommonStakingBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }

    func makeOnrampBaseDataBuilder(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) -> OnrampBaseDataBuilder {
        CommonOnrampBaseDataBuilder(
            config: userWalletInfo.config,
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )
    }
}
