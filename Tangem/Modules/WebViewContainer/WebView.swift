//
//  WebView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    var url: URL?
    var headers: [String: String] = [:]
    var popupUrl: Binding<URL?>?
    var urlActions: [String: (String) -> Void] = [:]
    var isLoading: Binding<Bool>?
    var contentInset: UIEdgeInsets?
    var timeoutSettings: WebViewTimeoutSettings?

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        view.isOpaque = false
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        if let contentInset {
            view.scrollView.contentInset = contentInset
        }

        if let url {
            AppLogger.info("Loading request with url: \(url)")
            var request = URLRequest(
                url: url,
                timeoutInterval: timeoutSettings?.interval ?? Constants.defaultWebViewTimeoutInterval
            )
            request.allHTTPHeaderFields = headers
            view.load(request)
        }

        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let urlActions: [String: (String) -> Void]
        var popupUrl: Binding<URL?>?
        var isLoading: Binding<Bool>?
        let fallbackURL: URL?

        init(
            urlActions: [String: (String) -> Void] = [:],
            popupUrl: Binding<URL?>?,
            isLoading: Binding<Bool>?,
            fallbackURL: URL?
        ) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
            self.fallbackURL = fallbackURL
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            AppLogger.info("Start to find decide for url \(String(describing: navigationAction.request.url?.absoluteString))")
            if let url = navigationAction.request.url?.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel)
                actionForURL(navigationAction.request.url!.absoluteString)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            popupUrl?.wrappedValue = navigationAction.request.url
            return nil
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            guard let fallbackURL else {
                return
            }

            isLoading?.wrappedValue = false
            webView.load(URLRequest(url: fallbackURL))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            urlActions: urlActions,
            popupUrl: popupUrl,
            isLoading: isLoading,
            fallbackURL: timeoutSettings?.fallbackURL
        )
    }
}

private extension WebView {
    enum Constants {
        static let defaultWebViewTimeoutInterval: TimeInterval = 60
    }
}
