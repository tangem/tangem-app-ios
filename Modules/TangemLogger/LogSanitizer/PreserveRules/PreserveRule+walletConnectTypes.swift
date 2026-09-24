//
//  PreserveRule+walletConnectTypes.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves full WalletConnect Swift type dumps that are intentionally allowed in logs,
    /// such as `WalletConnectURI(...)`, `Session(...)`, `Request(...)`, and `Proposal(...)`,
    /// so later broad redaction does not corrupt their structure or selected identifiers.
    static let walletConnectTypes = PreserveRule(
        placeholderPrefix: "WC_TYPE",
        pattern: Self.walletConnectTypesPattern
    )
}

/// Patterns are regex literals rather than `RegexBuilder` compositions: the Swift 6.4.0 runtime shipped
/// with iOS 27.0 corrupts a builder regex when a string literal is followed by an embedded regex that also
/// starts with a literal, which made this rule match arbitrary text. `ChoiceOf` only alternates and is unaffected.
private extension PreserveRule {
    static let walletConnectTypesPattern = Regex {
        ChoiceOf {
            walletConnectURI
            session
            request
            proposal
        }
    }

    /// [REDACTED_USERNAME], symKey is consider sensitive, so we only preserve first first part of the type.
    static let walletConnectURI = #/(?s)WalletConnectURI\(topic: (?:(?!, ).)*, version: (?:(?!, ).)*, symKey: /#

    // swiftformat:disable indent
    // SwiftFormat misreads escaped brackets inside multi-line regex literals and breaks their indentation.

    static let session = #/
        (?s)
        Session\(
        topic:\ (?:(?!,\ ).)*
        ,\ pairingTopic:\ (?:(?!,\ ).)*
        ,\ peer:\ (?:(?!,\ requiredNamespaces:\ ).)*
        ,\ requiredNamespaces:\ (?:(?!,\ namespaces:\ ).)*
        ,\ namespaces:\ (?:(?!,\ sessionProperties:\ ).)*
        ,\ sessionProperties:\ (?:(?!,\ ).)*
        ,\ scopedProperties:\ (?:(?!,\ ).)*
        ,\ expiryDate:\ (?:(?!\)).)+
        \)
        /#

    static let request = #/
        (?s)
        Request\(
        id:\ (?:(?!,\ ).)*
        ,\ topic:\ (?:(?!,\ ).)*
        ,\ method:\ (?:(?!,\ ).)*
        ,\ params:\ (?:(?!,\ chainId:\ ).)*
        ,\ chainId:\ (?:(?!,\ ).)*
        ,\ expiryTimestamp:\ (?:nil|Optional\(\d+\)|\d+)
        \)
        /#

    static let proposal = #/
        (?s)
        Proposal\(
        id:\ (?:(?!,\ ).)*
        ,\ pairingTopic:\ (?:(?!,\ ).)*
        ,\ proposer:\ (?:(?!,\ requiredNamespaces:\ ).)*
        ,\ requiredNamespaces:\ (?:(?!,\ optionalNamespaces:\ ).)*
        ,\ optionalNamespaces:\ (?:(?!,\ sessionProperties:\ ).)*
        ,\ sessionProperties:\ (?:(?!,\ scopedProperties:\ ).)*
        ,\ scopedProperties:\ (?:(?!,\ requests:\ ).)*
        ,\ requests:\ (?:(?!,\ proposal:\ ).)*
        ,\ proposal:\ WalletConnectSign\.SessionProposal\(
            relays:\ (?:(?!,\ proposer:\ ).)*
            ,\ proposer:\ (?:(?!,\ requiredNamespaces:\ ).)*
            ,\ requiredNamespaces:\ (?:(?!,\ optionalNamespaces:\ ).)*
            ,\ optionalNamespaces:\ (?:(?!,\ sessionProperties:\ ).)*
            ,\ sessionProperties:\ (?:(?!,\ scopedProperties:\ ).)*
            ,\ scopedProperties:\ (?:(?!,\ expiryTimestamp:\ ).)*
            ,\ expiryTimestamp:\ (?:(?!,\ requests:\ ).)*
            ,\ requests:\ (?:
                nil
                |
                Optional\(WalletConnectSign\.ProposalRequests\(authentication:\ (?:
                    nil
                    |
                    Optional\(\[
                    (?:
                        WalletConnectSign\.AuthPayload\(
                        domain:\ (?:(?!,\ aud:\ ).)*
                        ,\ aud:\ (?:(?!,\ version:\ ).)*
                        ,\ version:\ (?:(?!,\ nonce:\ ).)*
                        ,\ nonce:\ (?:(?!,\ chains:\ ).)*
                        ,\ chains:\ (?:(?!,\ type:\ ).)*
                        ,\ type:\ (?:(?!,\ iat:\ ).)*
                        ,\ iat:\ (?:(?!,\ nbf:\ ).)*
                        ,\ nbf:\ (?:(?!,\ exp:\ ).)*
                        ,\ exp:\ (?:(?!,\ statement:\ ).)*
                        ,\ statement:\ (?:(?!,\ requestId:\ ).)*
                        ,\ requestId:\ (?:(?!,\ resources:\ ).)*
                        ,\ resources:\ (?:(?!,\ signatureTypes:\ ).)*
                        ,\ signatureTypes:\ (?:nil|(?:(?!\)).)+)
                        \)
                        (?:
                            ,\ WalletConnectSign\.AuthPayload\(
                            domain:\ (?:(?!,\ aud:\ ).)*
                            ,\ aud:\ (?:(?!,\ version:\ ).)*
                            ,\ version:\ (?:(?!,\ nonce:\ ).)*
                            ,\ nonce:\ (?:(?!,\ chains:\ ).)*
                            ,\ chains:\ (?:(?!,\ type:\ ).)*
                            ,\ type:\ (?:(?!,\ iat:\ ).)*
                            ,\ iat:\ (?:(?!,\ nbf:\ ).)*
                            ,\ nbf:\ (?:(?!,\ exp:\ ).)*
                            ,\ exp:\ (?:(?!,\ statement:\ ).)*
                            ,\ statement:\ (?:(?!,\ requestId:\ ).)*
                            ,\ requestId:\ (?:(?!,\ resources:\ ).)*
                            ,\ resources:\ (?:(?!,\ signatureTypes:\ ).)*
                            ,\ signatureTypes:\ (?:nil|(?:(?!\)).)+)
                            \)
                        )*
                    )?
                    \]\)
                )\)\)
            )
            \)
        \)
        /#
    // swiftformat:enable indent
}
