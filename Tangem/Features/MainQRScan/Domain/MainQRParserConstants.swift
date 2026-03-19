//
//  MainQRParserConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MainQRParserConstants {
    static let walletConnectSchemeName = "wc"
    static let eip681TransferPath = "/transfer"
    static let genericTransferPrefix = "transfer/"
    static let httpSchemes = ["http://", "https://"]

    static let embeddedPayloadQueryKeys = [
        QueryKey.uri,
        QueryKey.deeplink,
        QueryKey.payload,
    ]

    static let destinationQueryKeys = [
        QueryKey.address,
        QueryKey.recipient,
        QueryKey.to,
    ]

    static let chainQueryKeys = [
        QueryKey.chain,
        QueryKey.network,
        QueryKey.blockchain,
    ]

    static let rawAmountQueryKeys = [
        QueryKey.amount,
        QueryKey.value,
        QueryKey.uint256,
    ]

    static let memoQueryKeys = [
        QueryKey.memo,
        QueryKey.message,
        QueryKey.tag,
        QueryKey.destinationTag,
    ]

    static let tokenContractQueryKeys = [
        QueryKey.contract,
        QueryKey.token,
    ]

    static let tokenSymbolQueryKeys = [
        QueryKey.symbol,
        QueryKey.ticker,
        QueryKey.token,
    ]

    static let eip681TransferAmountQueryKeys = [
        QueryKey.uint256,
        QueryKey.value,
    ]

    static let eip681TransferMemoQueryKeys = [
        QueryKey.memo,
        QueryKey.tag,
        QueryKey.message,
    ]

    static let eip681AmountQueryKeys = [
        QueryKey.value,
        QueryKey.amount,
    ]

    static let jsonChainKeys = [
        PayloadKey.chain,
        PayloadKey.network,
    ]

    static let jsonAmountKeys = [
        PayloadKey.amount,
        PayloadKey.value,
    ]

    static let jsonMemoKeys = [
        PayloadKey.memo,
        PayloadKey.tag,
    ]

    static let jsonTokenSymbolKeys = [
        PayloadKey.symbol,
        PayloadKey.ticker,
    ]

    enum QueryKey {
        static let uri = "uri"
        static let chainId = "chainid"
        static let address = "address"
        static let amount = "amount"
        static let value = "value"
        static let uint256 = "uint256"
        static let memo = "memo"
        static let tag = "tag"
        static let message = "message"
        static let deeplink = "deeplink"
        static let payload = "payload"
        static let recipient = "recipient"
        static let to = "to"
        static let chain = "chain"
        static let network = "network"
        static let blockchain = "blockchain"
        static let destinationTag = "destinationtag"
        static let contract = "contract"
        static let token = "token"
        static let symbol = "symbol"
        static let ticker = "ticker"
    }

    enum PayloadKey {
        static let address = "address"
        static let chain = "chain"
        static let network = "network"
        static let amount = "amount"
        static let value = "value"
        static let memo = "memo"
        static let tag = "tag"
        static let symbol = "symbol"
        static let ticker = "ticker"
    }
}
