//
//  SwapPayloadPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct SwapPayloadPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.swapPayload)
    func shouldPreserveKnownSwapDTOLogPayload(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.swapPayload)
    func shouldIgnoreUntypedOrUnexpectedSwapPayload(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_SWAP_PAYLOAD_\(index)"
    }

    static let exchangeDataRequest = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.exchangeDataRequest)
    static let exchangeDataResponse = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.exchangeDataResponse)
    static let exchangeStatusResponse = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.exchangeStatusResponse)
    static let exchangeSentRequest = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.exchangeSentRequest)
    static let exchangeSentResponse = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.exchangeSentResponse)
    static let decodedTransactionDetails = preserveLogTestCase(originalLog: RuleTestCases.SwapDTOLogs.decodedTransactionDetails)

    static let swapPayload = [
        RuleTestCases.Preserved.exchangeDataRequest,
        RuleTestCases.Preserved.exchangeDataResponse,
        RuleTestCases.Preserved.exchangeStatusResponse,
        RuleTestCases.Preserved.exchangeSentRequest,
        RuleTestCases.Preserved.exchangeSentResponse,
        RuleTestCases.Preserved.decodedTransactionDetails,
    ]

    static func preserveLogTestCase(originalLog: String) -> PreserveLogTestCase {
        PreserveLogTestCase(
            originalLog: originalLog,
            preservedLog: placeholder(),
            capturedValues: [Substring(originalLog)]
        )
    }
}

// MARK: - Ignored test cases

private extension RuleTestCases.Ignored {
    static let untypedSwapBlob = """
    "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55",
    "providerId": "okx-cross-chain",
    "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
    "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e",
    "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
    "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
    "rateType": "float",
    "status": "finished",
    "externalTxStatus": "finished",
    "txHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d",
    "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
    "fromNetwork": "polygon-pos",
    "fromDecimals": 6,
    "fromAmount": "9000000",
    "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f",
    "toNetwork": "arbitrum-one",
    "toDecimals": 8,
    "toAmount": "14428",
    "createdAt": "2024-09-19T06:35:22.312Z"
    """

    static let singlePreservedFieldName = #""txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55""#
    static let preservedFieldNameWithDifferentSpacing = #""fromAddress"   :   "0x0f0632254b1b45b835e5911E729871667E91BE12""#
    static let unknownTypedPayload = """
    Unknown swap payload:
    "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
    "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    """

    static let exchangeStatusResponseWithUnexpectedOrder = """
    Exchange status response payload:
    "providerId": "okx-cross-chain"
    "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
    "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
    "payinExtraId": "0xabcdef0123456789"
    "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "refundExtraId": "0xabcdef0123456789"
    "rateType": "float"
    "status": "finished"
    "externalTxId": "8d58d15b-04f4-4631-9a67-b481e3b7c114"
    "externalTxUrl": "https://www.okx.com/web3/dex-swap/0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
    "payinHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
    "payoutHash": "0xa3d53ce7f6f9a884d1b9ed62c1f7b872f7d4b2ac51d4276c908e8bb4ce1d3e9f"
    "refundNetwork": "polygon-pos"
    "refundContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
    "createdAt": "2024-09-19T06:35:22.312Z"
    "updatedAt": "2024-09-19T06:45:22.312Z"
    "payTill": "2024-09-19T07:35:22.312Z"
    "averageDuration": "900.0"
    "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
    "fromNetwork": "polygon-pos"
    "fromDecimals": "6"
    "fromAmount": "9000000"
    "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f"
    "toNetwork": "arbitrum-one"
    "toDecimals": "8"
    "toAmount": "14428"
    "toActualAmount": "14420"
    """

    static let swapPayload = [
        RuleTestCases.Ignored.untypedSwapBlob,
        RuleTestCases.Ignored.singlePreservedFieldName,
        RuleTestCases.Ignored.preservedFieldNameWithDifferentSpacing,
        RuleTestCases.Ignored.unknownTypedPayload,
        RuleTestCases.Ignored.exchangeStatusResponseWithUnexpectedOrder,
    ]
}

private extension RuleTestCases {
    enum SwapDTOLogs {
        static let exchangeDataRequest = """
        Exchange data request payload:
        "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
        "fromNetwork": "polygon-pos"
        "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f"
        "toNetwork": "arbitrum-one"
        "toDecimals": "8"
        "fromAmount": "9000000"
        "toAmount": "14428"
        "fromDecimals": "6"
        "providerId": "okx-cross-chain"
        "rateType": "float"
        "toAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        """

        static let exchangeDataResponse = """
        Exchange data response payload:
        "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
        "fromAmount": "9000000"
        "fromDecimals": "6"
        "toAmount": "14428"
        "toDecimals": "8"
        "payTill": "2024-09-19T07:35:22.312Z"
        """

        static let exchangeStatusResponse = """
        Exchange status response payload:
        "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
        "providerId": "okx-cross-chain"
        "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
        "payinExtraId": "0xabcdef0123456789"
        "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "refundExtraId": "0xabcdef0123456789"
        "rateType": "float"
        "status": "finished"
        "externalTxId": "8d58d15b-04f4-4631-9a67-b481e3b7c114"
        "externalTxUrl": "https://www.okx.com/web3/dex-swap/0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
        "payinHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
        "payoutHash": "0xa3d53ce7f6f9a884d1b9ed62c1f7b872f7d4b2ac51d4276c908e8bb4ce1d3e9f"
        "refundNetwork": "polygon-pos"
        "refundContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
        "createdAt": "2024-09-19T06:35:22.312Z"
        "updatedAt": "2024-09-19T06:45:22.312Z"
        "payTill": "2024-09-19T07:35:22.312Z"
        "averageDuration": "900.0"
        "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
        "fromNetwork": "polygon-pos"
        "fromDecimals": "6"
        "fromAmount": "9000000"
        "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f"
        "toNetwork": "arbitrum-one"
        "toDecimals": "8"
        "toAmount": "14428"
        "toActualAmount": "14420"
        """

        static let exchangeSentRequest = """
        Exchange sent request payload:
        "txHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
        "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
        "fromNetwork": "polygon-pos"
        "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
        "payinExtraId": "0xabcdef0123456789"
        """

        static let exchangeSentResponse = """
        Exchange sent response payload:
        "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
        "status": "finished"
        """

        static let decodedTransactionDetails = """
        Exchange data decoded transaction details payload:
        "requestId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
        "txType": "send"
        "txFrom": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "txTo": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
        "txExtraId": "0xabcdef0123456789"
        "txValue": "9000000"
        "otherNativeFee": "nil"
        "gas": "nil"
        "externalTxId": "8d58d15b-04f4-4631-9a67-b481e3b7c114"
        "externalTxUrl": "https://www.okx.com/web3/dex-swap/0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
        "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
        "payoutExtraId": "0xabcdef0123456789"
        """
    }
}

private extension SwapPayloadPreserveRuleTests {
    static func makeSUT() -> PreserveRule {
        PreserveRule.swapPayload
    }
}
