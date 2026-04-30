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
    static let walletConnectURI = Regex {
        "WalletConnectURI("
        property("topic")
        property("version")
        "symKey: "
    }

    static let session = Regex {
        "Session("
        property("topic")
        property("pairingTopic")
        property("peer", nextPropertyName: "requiredNamespaces")
        property("requiredNamespaces", nextPropertyName: "namespaces")
        property("namespaces", nextPropertyName: "sessionProperties")
        property("sessionProperties")
        property("scopedProperties")
        "expiryDate: "
        OneOrMore {
            NegativeLookahead { ")" }
            CharacterClass.any
        }
        ")"
    }

    static let request = Regex {
        "Request("
        property("id")
        property("topic")
        property("method")
        property("params", nextPropertyName: "chainId")
        property("chainId")
        "expiryTimestamp: "
        ChoiceOf {
            "nil"
            Regex {
                "Optional("
                OneOrMore(.digit)
                ")"
            }
            OneOrMore(.digit)
        }
        ")"
    }

    static let proposal = Regex {
        "Proposal("
        property("id")
        property("pairingTopic")
        property("proposer", nextPropertyName: "requiredNamespaces")
        property("requiredNamespaces", nextPropertyName: "optionalNamespaces")
        property("optionalNamespaces", nextPropertyName: "sessionProperties")
        property("sessionProperties", nextPropertyName: "scopedProperties")
        property("scopedProperties", nextPropertyName: "requests")
        property("requests", nextPropertyName: "proposal")
        "proposal: "
        proposalTail
        ")"
    }

    static let proposalTail = Regex {
        "WalletConnectSign.SessionProposal("
        property("relays", nextPropertyName: "proposer")
        property("proposer", nextPropertyName: "requiredNamespaces")
        property("requiredNamespaces", nextPropertyName: "optionalNamespaces")
        property("optionalNamespaces", nextPropertyName: "sessionProperties")
        property("sessionProperties", nextPropertyName: "scopedProperties")
        property("scopedProperties", nextPropertyName: "expiryTimestamp")
        property("expiryTimestamp", nextPropertyName: "requests")
        "requests: "
        ChoiceOf {
            "nil"
            Regex {
                "Optional(WalletConnectSign.ProposalRequests(authentication: "
                authenticationValue
                "))"
            }
        }
        ")"
    }

    static let authenticationValue = Regex {
        ChoiceOf {
            "nil"
            Regex {
                "Optional(["
                Optionally {
                    authPayloadValue
                    ZeroOrMore {
                        ", "
                        authPayloadValue
                    }
                }
                "])"
            }
        }
    }

    static let authPayloadValue = Regex {
        "WalletConnectSign.AuthPayload("
        property("domain", nextPropertyName: "aud")
        property("aud", nextPropertyName: "version")
        property("version", nextPropertyName: "nonce")
        property("nonce", nextPropertyName: "chains")
        property("chains", nextPropertyName: "type")
        property("type", nextPropertyName: "iat")
        property("iat", nextPropertyName: "nbf")
        property("nbf", nextPropertyName: "exp")
        property("exp", nextPropertyName: "statement")
        property("statement", nextPropertyName: "requestId")
        property("requestId", nextPropertyName: "resources")
        property("resources", nextPropertyName: "signatureTypes")
        "signatureTypes: "
        ChoiceOf {
            "nil"
            OneOrMore {
                NegativeLookahead { ")" }
                CharacterClass.any
            }
        }
        ")"
    }

    static func property(_ propertyName: Substring, suffix: some RegexComponent = ", ") -> Regex<Substring> {
        Regex {
            propertyName
            ": "
            ZeroOrMore {
                NegativeLookahead {
                    ", "
                }
                CharacterClass.any
            }
            suffix
        }
    }

    static func property(
        _ propertyName: Substring,
        nextPropertyName: Substring,
        suffix: some RegexComponent = ", "
    ) -> Regex<Substring> {
        Regex {
            propertyName
            ": "
            ZeroOrMore {
                NegativeLookahead {
                    ", "
                    nextPropertyName
                    ": "
                }
                CharacterClass.any
            }
            suffix
        }
    }
}
