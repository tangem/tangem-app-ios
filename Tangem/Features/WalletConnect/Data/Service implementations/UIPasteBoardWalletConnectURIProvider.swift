//
//  UIPasteBoardWalletConnectURIProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import class UIKit.UIPasteboard

struct UIPasteBoardWalletConnectURIProvider: WalletConnectURIProvider {
    private let pasteboard: UIPasteboard
    private let parser: WalletConnectURLParser

    init(pasteboard: UIPasteboard, parser: WalletConnectURLParser) {
        self.pasteboard = pasteboard
        self.parser = parser
    }

    func tryExtractClipboardURI() throws -> WalletConnectRequestURI? {
        guard let pasteboardString = pasteboard.string else {
            return nil
        }

        return try parser.parse(uriString: pasteboardString)
    }
}
