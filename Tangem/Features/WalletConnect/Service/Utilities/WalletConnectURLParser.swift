//
//  WalletConnectURLParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct ReownWalletKit.WalletConnectURI

public struct WalletConnectURLParser {
    func parse(uriString: String) throws(WalletConnectURIParsingError) -> WalletConnectRequestURI {
        let separatedURI = uriString.components(separatedBy: "@")

        // Parse wc version, u can see wc uri signature "wc:\(topic)@\(version)?\(queryString)"
        if separatedURI.last?.first == "1" {
            throw WalletConnectURIParsingError.unsupportedWalletConnectVersion(version: "1")
        }

        do {
            return .v2(try WalletConnectV2URI(uriString: uriString))
        } catch WalletConnectURI.Errors.expired {
            throw WalletConnectURIParsingError.expired
        } catch {
            throw WalletConnectURIParsingError.invalidFormat(uriString)
        }
    }

    func parse(url: URL) throws(WalletConnectURIParsingError) -> WalletConnectRequestURI? {
        guard let uri = extractURI(from: url) else {
            return nil
        }

        return try parse(uriString: uri)
    }

    private func extractURI(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.path == Constants.wcPrefix || components.host == Constants.wcHost,
              components.queryItems?.first?.name == Constants.uriName else {
            return nil
        }

        return components.query?.remove(Constants.uriPrefix)
    }
}

extension WalletConnectURLParser: IncomingActionURLParser {
    public func parse(_ url: URL) throws -> IncomingAction? {
        if let uri = try parse(url: url) {
            return .walletConnect(uri)
        }

        return nil
    }
}

extension WalletConnectURLParser {
    private enum Constants {
        static let uriPrefix = "\(uriName)="
        static let uriName = "uri"
        static let wcPrefix = "/\(wcHost)"
        static let wcHost = "wc"
    }
}

public enum WalletConnectRequestURI: Equatable {
    case v2(WalletConnectV2URI)

    var debugString: String {
        switch self {
        case .v2(let walletConnectV2URI):
            return walletConnectV2URI.absoluteString
        }
    }
}
