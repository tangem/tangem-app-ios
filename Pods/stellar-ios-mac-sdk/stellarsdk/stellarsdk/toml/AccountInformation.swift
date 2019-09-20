//
//  AccountInformation.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class AccountInformation {

    private enum Keys: String {
        case federationServer = "FEDERATION_SERVER"
        case authServer = "AUTH_SERVER"
        case transferServer = "TRANSFER_SERVER"
        case kycServer = "KYC_SERVER"
        case webAuthEndpoint = "WEB_AUTH_ENDPOINT"
        case signingKey = "SIGNING_KEY"
        case horizonUrl = "HORIZON_URL"
        case accounts = "ACCOUNTS"
        case uriRequestSigningKey = "URI_REQUEST_SIGNING_KEY"
        case version = "VERSION"
        case nodeNames = "NODE_NAMES" // depricated
        case ourValidators = "OUR_VALIDATORS" // depricated
        case assetValidator = "ASSET_VALIDATOR" // depricated
        case desiredBaseFee = "DESIRED_BASE_FEE" // depricated
        case desiredMaxTxPerLedger = "DESIRED_MAX_TX_PER_LEDGER" // depricated
        case knownPeers = "KNOWN_PEERS" // depricated
        case history = "HISTORY" // depricated
    }
    
    /// uses https:
    /// The endpoint for clients to resolve stellar addresses for users on your domain via SEP-2 federation protocol
    public let federationServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-3 Compliance Protocol
    public let authServer: String?
    
    /// uses https:
    /// The server used for SEP-6 Anchor/Client interoperability
    public let transferServer: String?
    
    /// uses https:
    /// The server used for SEP-12 Anchor/Client customer info transfer
    public let kycServer: String?
    
    /// uses https:
    /// The endpoint used for SEP-10 Web Authentication
    public let webAuthEndpoint: String?
    
    /// Stellar public key
    /// The signing key is used for the compliance protocol
    public let signingKey: String?
    
    /// url
    /// Location of public-facing Horizon instance (if one is offered)
    public let horizonUrl: String?
    
    /// list of "G... name" strings
    /// convenience mapping of common names to node IDs. You can use these common names in sections below instead of the less friendly nodeID. This is provided mainly to be compatible with the stellar-core.cfg
    @available(*, deprecated)
    public let nodeNames: [String]
    
    /// list of G... strings
    /// A list of Stellar accounts that are controlled by this domain. Names defined in NODE_NAMES can be used as well, prefixed with $.
    public let accounts: [String]
    
    /// list of G... strings
    /// A list of validator public keys that are declared to be used by this domain for validating ledgers. They are authorized signers for the domain. Names defined in NODE_NAMES can be used as well, prefixed with $.
    @available(*, deprecated)
    public let ourValidators: [String]
    
    /// G... string
    /// The validator through which the issuer pledges to honor redemption transactions, and which therefore maintains the authoritative ownership records for assets issued by this organization. Specified as a public key G... or NODE_NAME prefixed with $. This field may also contain a list of validators. In this case, transactions must be processed by all listed validators. In the event that this field specifies multiple validators and they do not all agree, then the authoritative ownership records will be the last ledger number on which all validators agree.
    @available(*, deprecated)
    public let assetValidator: String?
    
    /// Your preference for the Stellar network base fee, expressed in stroops
    @available(*, deprecated)
    public let desiredBaseFee: Int?
    
    /// Your preference for max number of transactions per ledger close
    @available(*, deprecated)
    public let desiredMaxTxPerLedger: Int?
    
    /// list of strings
    /// List of known Stellar core servers, listed from most to least trusted if known. Can be IP:port, IPv6:port, or domain:port with the :port optional.
    @available(*, deprecated)
    public let knownPeers: [String]
    
    /// list of URL strings
    /// List of history archives maintained by this domain
    @available(*, deprecated)
    public let history: [String]
    
    /// string
    /// The version of SEP-1 your stellar.toml adheres to. This helps parsers know which fields to expect.
    public let version: String?
    
    /// URI request signing key
    public let uriRequestSigningKey: String?
    
    public init(fromToml toml:Toml) {
        federationServer = toml.string(Keys.federationServer.rawValue)
        authServer = toml.string(Keys.authServer.rawValue)
        transferServer = toml.string(Keys.transferServer.rawValue)
        kycServer = toml.string(Keys.kycServer.rawValue)
        webAuthEndpoint = toml.string(Keys.webAuthEndpoint.rawValue)
        signingKey = toml.string(Keys.signingKey.rawValue)
        horizonUrl = toml.string(Keys.horizonUrl.rawValue)
        nodeNames = toml.array(Keys.nodeNames.rawValue) ?? []
        accounts = toml.array(Keys.accounts.rawValue) ?? []
        ourValidators = toml.array(Keys.ourValidators.rawValue) ?? []
        assetValidator = toml.string(Keys.assetValidator.rawValue)
        desiredBaseFee = toml.int(Keys.desiredBaseFee.rawValue)
        desiredMaxTxPerLedger = toml.int(Keys.desiredMaxTxPerLedger.rawValue)
        knownPeers = toml.array(Keys.knownPeers.rawValue) ?? []
        history = toml.array(Keys.history.rawValue) ?? []
        version = toml.string(Keys.version.rawValue)
        uriRequestSigningKey = toml.string(Keys.uriRequestSigningKey.rawValue)
    }
    
}
