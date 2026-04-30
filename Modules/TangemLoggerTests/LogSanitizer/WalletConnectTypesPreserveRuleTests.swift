//
//  WalletConnectTypesPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct WalletConnectTypesPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.knownWalletConnectTypes)
    func shouldPreserveKnownWalletConnectTypes(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func placeholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_WC_TYPE_\(index)"
    }

    static let walletConnectURIPrefix: Substring = #"WalletConnectURI(topic:"#
        + #" dd6bfc7a0fdce707e76bbc0894f0fa9c0a569aaefabcd17ff8775891e2ecd579","#
        + #" version: "2", symKey: "#

    static let walletConnectURISuffix: Substring = #""e8cc7d1090c94f658fcf879836c73fcfc3237cb1725daeadb832fcc5af415a78","#
        + #" relay: WalletConnectUtils.RelayProtocolOptions(protocol: "irn", data: nil),"#
        + #" methods: nil, expiryTimestamp: 1777471044)"#

    static let sessionRaw: Substring = #"Session(topic:"#
        + #" "2696796e2ee3fe84c829b958f12a6bcb5dda28bd2ea59829a686941b3c2918f5", pairingTopic:"#
        + #" "dd6bfc7a0fdce707e76bbc0894f0fa9c0a569aaefabcd17ff8775891e2ecd579", peer:"#
        + #" WalletConnectPairing.AppMetadata(name: "React App", description:"#
        + #" App to test WalletConnect network", url: "https://react-app.walletconnect.com","#
        + #" icons: [], redirect: nil),"#
        + #" requiredNamespaces: [:], namespaces: ["eip155":"#
        + #" WalletConnectSign.SessionNamespace(chains: Optional([eip155:1, eip155:42161]),"#
        + #" accounts: [], methods: Set(["eth_sendTransaction", "personal_sign"]),"#
        + #" events: Set(["chainChanged", "accountsChanged"]))], sessionProperties: nil,"#
        + #" scopedProperties: nil, expiryDate: 2026-05-06 13:53:43 +0000)"#

    static let proposalRaw: Substring = #"Proposal(id: "755d0d6739c268e4edc387d7aa1a45f2850745745957a1f58efe0bd4f3daca6a", pairingTopic: "dd6bfc7a0fdce707e76bbc0894f0fa9c0a569aaefabcd17ff8775891e2ecd579", proposer: WalletConnectPairing.AppMetadata(name: "React App", description: "App to test WalletConnect network", url: "https://react-app.walletconnect.com", icons: ["https://avatars.githubusercontent.com/u/37784886"], redirect: nil), requiredNamespaces: [:], optionalNamespaces: Optional(["stacks": WalletConnectSign.ProposalNamespace(chains: Optional([stacks:1]), methods: Set(["stx_signMessage", "stx_transferStx"]), events: Set(["stx_chainChanged", "stx_accountsChanged"])), "mvx": WalletConnectSign.ProposalNamespace(chains: Optional([mvx:1]), methods: Set(["mvx_cancelAction", "mvx_signTransactions", "mvx_signMessage", "mvx_signTransaction", "mvx_signLoginToken", "mvx_signNativeAuthToken"]), events: Set([])), "eip155": WalletConnectSign.ProposalNamespace(chains: Optional([eip155:1, eip155:10, eip155:100, eip155:137, eip155:42161, eip155:42220, eip155:324, eip155:56, eip155:143, eip155:36900]), methods: Set(["eth_sendTransaction", "personal_sign"]), events: Set(["chainChanged", "accountsChanged"])), "tezos": WalletConnectSign.ProposalNamespace(chains: Optional([tezos:mainnet]), methods: Set(["tezos_getAccounts", "tezos_sign", "tezos_send"]), events: Set([])), "tron": WalletConnectSign.ProposalNamespace(chains: Optional([tron:0x2b6653dc]), methods: Set(["tron_sendTransaction", "tron_signTransaction", "tron_signMessage"]), events: Set([]))]), sessionProperties: nil, scopedProperties: nil, requests: Optional(WalletConnectSign.ProposalRequests(authentication: Optional([WalletConnectSign.AuthPayload(domain: "react-app.walletconnect.com", aud: "https://react-app.walletconnect.com", version: "1", nonce: "1", chains: ["eip155:1", "eip155:10", "eip155:100", "eip155:137", "eip155:42161", "eip155:42220", "eip155:324", "eip155:56", "eip155:143", "eip155:36900", "stacks:1", "tron:0x2b6653dc", "mvx:1", "tezos:mainnet"], type: "caip122", iat: "2026-04-29T13:52:24.409Z", nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil, signatureTypes: nil)]))), proposal: WalletConnectSign.SessionProposal(relays: [WalletConnectUtils.RelayProtocolOptions(protocol: "irn", data: nil)], proposer: WalletConnectSign.Participant(publicKey: "755d0d6739c268e4edc387d7aa1a45f2850745745957a1f58efe0bd4f3daca6a", metadata: WalletConnectPairing.AppMetadata(name: "React App", description: "App to test WalletConnect network", url: "https://react-app.walletconnect.com", icons: ["https://avatars.githubusercontent.com/u/37784886"], redirect: nil)), requiredNamespaces: [:], optionalNamespaces: Optional(["stacks": WalletConnectSign.ProposalNamespace(chains: Optional([stacks:1]), methods: Set(["stx_signMessage", "stx_transferStx"]), events: Set(["stx_chainChanged", "stx_accountsChanged"])), "mvx": WalletConnectSign.ProposalNamespace(chains: Optional([mvx:1]), methods: Set(["mvx_cancelAction", "mvx_signTransactions", "mvx_signMessage", "mvx_signTransaction", "mvx_signLoginToken", "mvx_signNativeAuthToken"]), events: Set([])), "eip155": WalletConnectSign.ProposalNamespace(chains: Optional([eip155:1, eip155:10, eip155:100, eip155:137, eip155:42161, eip155:42220, eip155:324, eip155:56, eip155:143, eip155:36900]), methods: Set(["eth_sendTransaction", "personal_sign"]), events: Set(["chainChanged", "accountsChanged"])), "tezos": WalletConnectSign.ProposalNamespace(chains: Optional([tezos:mainnet]), methods: Set(["tezos_getAccounts", "tezos_sign", "tezos_send"]), events: Set([])), "tron": WalletConnectSign.ProposalNamespace(chains: Optional([tron:0x2b6653dc]), methods: Set(["tron_sendTransaction", "tron_signTransaction", "tron_signMessage"]), events: Set([]))]), sessionProperties: nil, scopedProperties: nil, expiryTimestamp: Optional(1777471744), requests: Optional(WalletConnectSign.ProposalRequests(authentication: Optional([WalletConnectSign.AuthPayload(domain: "react-app.walletconnect.com", aud: "https://react-app.walletconnect.com", version: "1", nonce: "1", chains: ["eip155:1", "eip155:10", "eip155:100", "eip155:137", "eip155:42161", "eip155:42220", "eip155:324", "eip155:56", "eip155:143", "eip155:36900", "stacks:1", "tron:0x2b6653dc", "mvx:1", "tezos:mainnet"], type: "caip122", iat: "2026-04-29T13:52:24.409Z", nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil, signatureTypes: nil)])))))"#

    static let requestRaw: Substring = #"Request(id: 1777470901564335, topic:"#
        + #" 2696796e2ee3fe84c829b958f12a6bcb5dda28bd2ea59829a686941b3c2918f5","#
        + #" method: "personal_sign", params: AnyCodable: "["#
        + "0x4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031373737343730393031353633,"
        + #"0xe34979EA46a0Bb49f0E483f163C79be02101cD1B"]", chainId: eip155:42161,"#
        + #" expiryTimestamp: Optional(1777471801))"#

    static let walletConnectURI = PreserveLogTestCase(
        originalLog: "Trying to pair client: \(walletConnectURIPrefix + walletConnectURISuffix). Good luck",
        preservedLog: "Trying to pair client: \(placeholder() + walletConnectURISuffix). Good luck",
        capturedValues: [walletConnectURIPrefix]
    )

    static let session = PreserveLogTestCase(
        originalLog: "Session established: \(sessionRaw)",
        preservedLog: "Session established: \(placeholder())",
        capturedValues: [sessionRaw]
    )

    static let proposal = PreserveLogTestCase(
        originalLog: "Session proposal: \(proposalRaw)",
        preservedLog: "Session proposal: \(placeholder())",
        capturedValues: [proposalRaw]
    )

    static let request = PreserveLogTestCase(
        originalLog: "App [Wallet Connect] <WCServiceV2: 0x12345678> Receive message request: \(requestRaw)",
        preservedLog: "App [Wallet Connect] <WCServiceV2: 0x12345678> Receive message request: \(placeholder())",
        capturedValues: [requestRaw]
    )

    static let combined = PreserveLogTestCase(
        originalLog: "Huge log of request: \(requestRaw),"
            + " session: \(sessionRaw)"
            + " proposal: \(proposalRaw)",
        preservedLog: "Huge log of request: \(placeholder()),"
            + " session: \(placeholder(for: 1))"
            + " proposal: \(placeholder(for: 2))",
        capturedValues: [requestRaw, sessionRaw, proposalRaw]
    )

    static let knownWalletConnectTypes = [
        RuleTestCases.Preserved.walletConnectURI,
        RuleTestCases.Preserved.session,
        RuleTestCases.Preserved.proposal,
        RuleTestCases.Preserved.request,
        RuleTestCases.Preserved.combined,
    ]
}

private extension WalletConnectTypesPreserveRuleTests {
    static func makeSUT() -> PreserveRule {
        PreserveRule.walletConnectTypes
    }
}
