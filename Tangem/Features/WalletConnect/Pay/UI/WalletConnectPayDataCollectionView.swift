//
//  WalletConnectPayDataCollectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit
import TangemAssets

struct WalletConnectPayDataCollectionView: View {
    let url: URL
    let onComplete: () -> Void
    let onError: (String) -> Void

    var body: some View {
        WalletConnectPayWebView(url: url, onComplete: onComplete, onError: onError)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Text("Tangem doesn't collect or store this data.")
                    .font(.footnote)
                    .foregroundStyle(Colors.Text.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Colors.Background.secondary)
            }
    }
}

private struct WalletConnectPayWebView: UIViewRepresentable {
    let url: URL
    let onComplete: () -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: Constants.messageHandlerName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private let onComplete: () -> Void
        private let onError: (String) -> Void

        init(onComplete: @escaping () -> Void, onError: @escaping (String) -> Void) {
            self.onComplete = onComplete
            self.onError = onError
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard
                let body = message.body as? String,
                let data = body.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = json["type"] as? String
            else {
                return
            }

            DispatchQueue.main.async {
                switch type {
                case "IC_COMPLETE":
                    self.onComplete()
                case "IC_ERROR":
                    self.onError(json["error"] as? String ?? "Information capture failed")
                default:
                    break
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url, let host = url.host else {
                decisionHandler(.allow)
                return
            }

            guard Constants.trustedHosts.contains(host) else {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }

    private enum Constants {
        static let messageHandlerName = "payDataCollectionComplete"
        static let trustedHosts = [
            "dev.pay.walletconnect.com",
            "staging.pay.walletconnect.com",
            "pay.walletconnect.com",
        ]
    }
}
