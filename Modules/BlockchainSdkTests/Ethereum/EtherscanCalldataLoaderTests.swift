//
//  EtherscanCalldataLoaderTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import TangemFoundation
import TangemNetworkUtils
import Testing

@Suite("Etherscan calldata of an upgrade row, loaded by hash", .timeLimit(.minutes(1)))
struct EtherscanCalldataLoaderTests {
    @Test("Both legs of a wrapped call get its calldata from a single lookup")
    func bothLegsShareOneLookup() async {
        let (sut, proxy) = makeSUT(replies: [Self.sendHash: [.transaction(input: Self.calldata)]])

        let restored = await sut.restoringMissingCalldata(in: page([.withdrawLeg(hash: Self.sendHash), .sendLeg(hash: Self.sendHash)]))

        #expect(inputs(of: restored) == [Self.calldata, Self.calldata])
        #expect(proxy.requestedHashes == [Self.sendHash])
    }

    @Test("A row of another call, or one that already carries its calldata, costs no lookup", arguments: UntouchedRow.allCases)
    func rowThatNeedsNoLookupIsLeftAlone(row: UntouchedRow) async {
        let (sut, proxy) = makeSUT(replies: [:])
        let transaction = row.transaction

        let restored = await sut.restoringMissingCalldata(in: page([transaction]))

        #expect(inputs(of: restored) == [transaction.input])
        #expect(proxy.requestedHashes.isEmpty)
    }

    @Test("Loaded calldata is not asked for again on the next load")
    func loadedCalldataIsKept() async {
        let (sut, proxy) = makeSUT(replies: [Self.sendHash: [.transaction(input: Self.calldata)]])

        _ = await sut.restoringMissingCalldata(in: page([.sendLeg(hash: Self.sendHash)]))
        let restored = await sut.restoringMissingCalldata(in: page([.sendLeg(hash: Self.sendHash)]))

        #expect(inputs(of: restored) == [Self.calldata])
        #expect(proxy.requestedHashes == [Self.sendHash])
    }

    @Test(
        "A failed lookup leaves the row as it was and is asked again on the next load",
        arguments: [Reply.serverError, .transactionNotFound]
    )
    func failedLookupIsAskedAgain(failure: Reply) async {
        let (sut, _) = makeSUT(replies: [Self.sendHash: [failure, .transaction(input: Self.calldata)]])

        let failed = await sut.restoringMissingCalldata(in: page([.sendLeg(hash: Self.sendHash)]))
        let restored = await sut.restoringMissingCalldata(in: page([.sendLeg(hash: Self.sendHash)]))

        #expect(inputs(of: failed) == [Self.missingCalldata])
        #expect(inputs(of: restored) == [Self.calldata])
    }

    @Test("A rate-limited lookup is tried once more")
    func rateLimitedLookupIsRetriedOnce() async {
        let (sut, proxy) = makeSUT(replies: [Self.sendHash: [.rateLimit, .transaction(input: Self.calldata)]])

        let restored = await sut.restoringMissingCalldata(in: page([.sendLeg(hash: Self.sendHash)]))

        #expect(inputs(of: restored) == [Self.calldata])
        #expect(proxy.requestedHashes == [Self.sendHash, Self.sendHash])
    }

    @Test("Once the rate limit outlasts the retry, the rest of the page is not looked up")
    func rateLimitStopsTheLookups() async {
        let (sut, proxy) = makeSUT(replies: [
            Self.sendHash: [.rateLimit, .rateLimit],
            Self.secondHash: [.transaction(input: Self.calldata)],
        ])

        let restored = await sut.restoringMissingCalldata(
            in: page([.sendLeg(hash: Self.sendHash), .sendLeg(hash: Self.secondHash)])
        )

        #expect(inputs(of: restored) == [Self.missingCalldata, Self.missingCalldata])
        #expect(proxy.requestedHashes == [Self.sendHash, Self.sendHash])
    }
}

// MARK: - Helpers

private extension EtherscanCalldataLoaderTests {
    static let sendHash = "0x89fdc2d59fb40fb8ca82e88ac10271c8734ab0ec7ef715cb0d84541378586eeb"
    static let secondHash = "0x69432d9d7800000000000000000000000000000000000000000000000000000a"
    static let missingCalldata = "deprecated"

    static var calldata: String {
        YieldModuleUpgradeCalldata.wrapping(
            YieldModuleUpgradeCalldata.yieldSend(token: Address.token, to: Address.recipient, amount: 100_000),
            implementation: YieldModuleUpgradeCalldata.v3Implementation
        )
    }

    func makeSUT(replies: [String: [Reply]]) -> (sut: EtherscanCalldataLoader, proxy: EtherscanProxySpy) {
        let proxy = EtherscanProxySpy(replies: replies)
        let provider = TangemProvider<EtherscanTransactionHistoryTarget>(configuration: EtherscanProxyURLProtocol.makeConfiguration())
        let sut = EtherscanCalldataLoader(
            networkProvider: provider,
            targetConfiguration: .etherscan(chainId: 137, apiKey: "apiKey", baseURL: EtherscanProxyURLProtocol.makeBaseURL(answering: proxy))
        )

        return (sut, proxy)
    }

    func page(_ transactions: [EtherscanTransactionHistoryResult.Transaction]) -> EtherscanTransactionHistoryResult {
        EtherscanTransactionHistoryResult(status: "1", message: "OK", result: .transactions(transactions))
    }

    func inputs(of result: EtherscanTransactionHistoryResult) -> [String?] {
        guard case .transactions(let transactions) = result.result else {
            return []
        }

        return transactions.map(\.input)
    }

    enum Address {
        static let wallet = "0x179d3bc82a00000000000000000000000000beef"
        static let token = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
        static let aToken = "0x6ab707aca953edaefbc4fd23ba73294241490620"
        static let recipient = "0xe8d5849d4ea5335775e881bb076ed172e8612dd3"
    }
}

// MARK: - Arguments

extension EtherscanCalldataLoaderTests {
    enum UntouchedRow: CaseIterable {
        case anotherCall
        case upgradeWithCalldata

        var transaction: EtherscanTransactionHistoryResult.Transaction {
            switch self {
            case .anotherCall:
                .sendLeg(hash: EtherscanCalldataLoaderTests.sendHash, methodId: YieldModuleUpgradeCalldata.yieldSendMethodId)
            case .upgradeWithCalldata:
                .sendLeg(hash: EtherscanCalldataLoaderTests.sendHash, input: EtherscanCalldataLoaderTests.calldata)
            }
        }
    }

    enum Reply: Equatable, Sendable {
        case transaction(input: String?)
        case transactionNotFound
        case rateLimit
        case serverError

        var statusCode: Int {
            self == .serverError ? 500 : 200
        }

        var body: String {
            switch self {
            case .transaction(let input):
                let inputField = input.map { #","input":"\#($0)""# } ?? ""
                return #"{"jsonrpc":"2.0","id":1,"result":{"hash":"0xdeadbeef"\#(inputField)}}"#
            case .transactionNotFound:
                return #"{"jsonrpc":"2.0","id":1,"result":null}"#
            case .rateLimit:
                return #"{"status":"0","message":"NOTOK","result":"Max calls per sec rate limit reached (5/sec)"}"#
            case .serverError:
                return ""
            }
        }
    }
}

// MARK: - Test fixtures

private extension EtherscanTransactionHistoryResult.Transaction {
    static func sendLeg(
        hash: String,
        methodId: String = UpgradeToAndCallMethod.methodId,
        input: String = EtherscanCalldataLoaderTests.missingCalldata
    ) -> Self {
        row(hash: hash, from: EtherscanCalldataLoaderTests.Address.wallet, to: EtherscanCalldataLoaderTests.Address.recipient, methodId: methodId, input: input)
    }

    static func withdrawLeg(hash: String) -> Self {
        row(
            hash: hash,
            from: EtherscanCalldataLoaderTests.Address.aToken,
            to: EtherscanCalldataLoaderTests.Address.wallet,
            methodId: UpgradeToAndCallMethod.methodId,
            input: EtherscanCalldataLoaderTests.missingCalldata
        )
    }

    private static func row(hash: String, from: String, to: String, methodId: String, input: String) -> Self {
        .init(
            confirmations: "10",
            contractAddress: EtherscanCalldataLoaderTests.Address.token,
            from: from,
            functionName: "",
            methodId: methodId,
            gasPrice: "30000000000",
            gasUsed: "396754",
            hash: hash,
            input: input,
            isError: "0",
            timeStamp: "1700000000",
            to: to,
            txReceiptStatus: "1",
            value: "100000"
        )
    }
}

// MARK: - Stubs

private final class EtherscanProxySpy: Sendable {
    private let state: OSAllocatedUnfairLock<State>

    init(replies: [String: [EtherscanCalldataLoaderTests.Reply]]) {
        state = OSAllocatedUnfairLock(initialState: State(replies: replies))
    }

    var requestedHashes: [String] {
        state.withLock { $0.requestedHashes }
    }

    func reply(forHash hash: String) -> EtherscanCalldataLoaderTests.Reply {
        state.withLock { state in
            state.requestedHashes.append(hash)

            guard var replies = state.replies[hash], let reply = replies.first else {
                return .serverError
            }

            if replies.count > 1 {
                replies.removeFirst()
                state.replies[hash] = replies
            }

            return reply
        }
    }
}

private extension EtherscanProxySpy {
    struct State {
        var replies: [String: [EtherscanCalldataLoaderTests.Reply]]
        var requestedHashes: [String] = []
    }
}

private final class EtherscanProxyURLProtocol: URLProtocol {
    private static let proxies = OSAllocatedUnfairLock(initialState: [String: EtherscanProxySpy]())

    static func makeBaseURL(answering proxy: EtherscanProxySpy) -> URL {
        let host = "\(UUID().uuidString.lowercased()).etherscan.test"
        proxies.withLock { $0[host] = proxy }

        return URL(string: "https://\(host)/v2")!
    }

    static func makeConfiguration() -> TangemProviderConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EtherscanProxyURLProtocol.self]

        return TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let proxy = url.host.flatMap({ host in Self.proxies.withLock { $0[host] } }),
            let hash = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "txhash" })?.value
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let reply = proxy.reply(forHash: hash)

        guard let response = HTTPURLResponse(url: url, statusCode: reply.statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
