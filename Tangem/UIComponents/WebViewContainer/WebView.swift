//
//  WebView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemNetworkUtils

@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    var url: URL?
    /// Inline HTML to load instead of `url` (e.g. the support chat widget).
    var htmlString: String?
    /// Base URL used with `htmlString` (origin for storage / CORS).
    var baseURL: URL?
    var headers: [String: String] = [:]
    var popupUrl: Binding<URL?>?
    var urlActions: [String: (String) -> Void] = [:]
    var isLoading: Binding<Bool>?
    var contentInset: UIEdgeInsets?
    var timeoutSettings: WebViewTimeoutSettings?

    /// Allow page JavaScript to run. Documents keep it off; the chat widget needs it on.
    var allowsJavaScript: Bool = false
    /// Validate Certificate Transparency on the server trust challenge.
    var validatesCertificateTransparency: Bool = false
    /// JS → native bridge: handler name → callback with the message body.
    var messageHandlers: [String: (Any) -> Void] = [:]
    /// Called with the created `WKWebView` so the caller can keep a reference (evaluate JS / reload).
    var onMakeWebView: ((WKWebView) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = .nonPersistent()
        configuration.mediaTypesRequiringUserActionForPlayback = []

        for name in messageHandlers.keys {
            configuration.userContentController.add(context.coordinator, name: name)
        }

        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        view.isOpaque = false
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        if let contentInset {
            view.scrollView.contentInset = contentInset
        }

        if let htmlString {
            view.loadHTMLString(htmlString, baseURL: baseURL)
        } else if let url {
            AppLogger.info("Loading request with url: \(url)")
            var request = URLRequest(
                url: url,
                timeoutInterval: timeoutSettings?.interval ?? Constants.defaultWebViewTimeoutInterval
            )
            request.allHTTPHeaderFields = headers
            view.load(request)
        }

        onMakeWebView?(view)
        return view
    }

    /// The web view loads its source once in `makeUIView`; changing `url`/`htmlString`/config
    /// afterwards has no effect. Drive runtime changes imperatively via `onMakeWebView`
    /// (reload / evaluate JS), or re-create the view to apply new inputs.
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Memory leak fix
        uiView.stopLoading()
        uiView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let urlActions: [String: (String) -> Void]
        var popupUrl: Binding<URL?>?
        var isLoading: Binding<Bool>?
        let fallbackURL: URL?
        let allowsJavaScript: Bool
        let validatesCertificateTransparency: Bool
        let messageHandlers: [String: (Any) -> Void]
        let reloadSource: ReloadSource?

        init(
            urlActions: [String: (String) -> Void] = [:],
            popupUrl: Binding<URL?>?,
            isLoading: Binding<Bool>?,
            fallbackURL: URL?,
            allowsJavaScript: Bool,
            validatesCertificateTransparency: Bool,
            messageHandlers: [String: (Any) -> Void],
            reloadSource: ReloadSource?
        ) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
            self.fallbackURL = fallbackURL
            self.allowsJavaScript = allowsJavaScript
            self.validatesCertificateTransparency = validatesCertificateTransparency
            self.messageHandlers = messageHandlers
            self.reloadSource = reloadSource
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            preferences: WKWebpagePreferences,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
        ) {
            preferences.allowsContentJavaScript = allowsJavaScript

            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.allow, preferences)
                return
            }

            guard requestURL.scheme != Constants.fileURLScheme else { // Block file:// navigation
                AppLogger.warning("Attempt load file:// url \(requestURL)")
                decisionHandler(.cancel, preferences)
                return
            }

            AppLogger.info("Start to find decide for url \(String(describing: requestURL.absoluteString))")

            let tangemURL = AppEnvironment.current.tangemComBaseUrl

            let hostMatch = tangemURL.host() == requestURL.host()

            if hostMatch,
               let url = requestURL.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel, preferences)
                actionForURL(navigationAction.request.url!.absoluteString)
                return
            }

            decisionHandler(.allow, preferences)
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            guard
                validatesCertificateTransparency,
                challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let (disposition, credential) = TangemTrustEvaluatorUtil.evaluate(challenge: challenge)
            completionHandler(disposition, credential)
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
            guard let fallbackURL, let htmlString = try? String(contentsOf: fallbackURL, encoding: .utf8) else {
                return
            }

            isLoading?.wrappedValue = false
            webView.loadHTMLString(htmlString, baseURL: nil)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            messageHandlers[message.name]?(message.body)
        }

        /// The web content process can be terminated under memory pressure (e.g. after the
        /// system file/photo picker opens on low-RAM devices), leaving a blank white page that
        /// never recovers on its own. Reload the original source to bring the content back.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            AppLogger.warning("WebView content process terminated — reloading")

            switch reloadSource {
            case .html(let htmlString, let baseURL):
                webView.loadHTMLString(htmlString, baseURL: baseURL)
            case .request(let url, let headers, let timeoutInterval):
                var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
                request.allHTTPHeaderFields = headers
                webView.load(request)
            case nil:
                break
            }
        }
    }

    enum ReloadSource {
        case html(String, baseURL: URL?)
        case request(URL, headers: [String: String], timeoutInterval: TimeInterval)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            urlActions: urlActions,
            popupUrl: popupUrl,
            isLoading: isLoading,
            fallbackURL: timeoutSettings?.fallbackURL,
            allowsJavaScript: allowsJavaScript,
            validatesCertificateTransparency: validatesCertificateTransparency,
            messageHandlers: messageHandlers,
            reloadSource: reloadSource
        )
    }

    private var reloadSource: ReloadSource? {
        if let htmlString {
            return .html(htmlString, baseURL: baseURL)
        } else if let url {
            return .request(
                url,
                headers: headers,
                timeoutInterval: timeoutSettings?.interval ?? Constants.defaultWebViewTimeoutInterval
            )
        } else {
            return nil
        }
    }
}

private extension WebView {
    enum Constants {
        static let defaultWebViewTimeoutInterval: TimeInterval = 60
        static let fileURLScheme: String = "file"
    }
}
