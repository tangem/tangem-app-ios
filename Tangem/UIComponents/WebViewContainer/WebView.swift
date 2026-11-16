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
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
    var timeoutSettings: WebViewTimeoutSettings?

    /// Allow page JavaScript to run. Documents keep it off; the chat widget needs it on.
    var allowsJavaScript: Bool = false
    /// Validate Certificate Transparency on the server trust challenge.
    var validatesCertificateTransparency: Bool = false
    /// JS → native bridge: handler name → callback with the message body.
    var messageHandlers: [String: (Any) -> Void] = [:]
    /// Called with the created `WKWebView` so the caller can keep a reference (evaluate JS / reload).
    var onMakeWebView: ((WKWebView) -> Void)?
    var restrictedLoading: RestrictedLoading?

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
        view.scrollView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior

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
        @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

        let urlActions: [String: (String) -> Void]
        var popupUrl: Binding<URL?>?
        var isLoading: Binding<Bool>?
        let fallbackURL: URL?
        let allowsJavaScript: Bool
        let validatesCertificateTransparency: Bool
        let messageHandlers: [String: (Any) -> Void]
        let restrictedLoading: RestrictedLoading?

        private var initialLoad: InitialLoad = .loading

        init(
            urlActions: [String: (String) -> Void] = [:],
            popupUrl: Binding<URL?>?,
            isLoading: Binding<Bool>?,
            fallbackURL: URL?,
            allowsJavaScript: Bool,
            validatesCertificateTransparency: Bool,
            messageHandlers: [String: (Any) -> Void],
            restrictedLoading: RestrictedLoading? = nil
        ) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
            self.fallbackURL = fallbackURL
            self.allowsJavaScript = allowsJavaScript
            self.validatesCertificateTransparency = validatesCertificateTransparency
            self.messageHandlers = messageHandlers
            self.restrictedLoading = restrictedLoading
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

            let isLinkOfOurs = requestURL.absoluteString.lowercased().starts(with: IncomingActionConstants.appScheme)

            if let restrictedLoading, navigationAction.targetFrame?.isMainFrame ?? true, !restrictedLoading.isAllowed(requestURL) {
                refuse(requestURL)
                decisionHandler(.cancel, preferences)
                return
            }

            if restrictedLoading != nil, isLinkOfOurs {
                AppLogger.info("A link of ours from a restricted page is cancelled: \(requestURL.host ?? "")")
                decisionHandler(.cancel, preferences)
                return
            }

            AppLogger.info("Start to find decide for url \(String(describing: requestURL.absoluteString))")

            // A link of ours goes to the deeplink system, which validates and parses it like every other
            // incoming link.
            if isLinkOfOurs,
               incomingActionHandler.handleIncomingURL(requestURL) {
                decisionHandler(.cancel, preferences)
                return
            }

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

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void
        ) {
            guard let restrictedLoading, navigationResponse.isForMainFrame else {
                decisionHandler(.allow)
                return
            }

            if let responseURL = navigationResponse.response.url, !restrictedLoading.isAllowed(responseURL) {
                refuse(responseURL)
                decisionHandler(.cancel)
                return
            }

            if initialLoad == .loading,
               let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode,
               statusCode >= Constants.firstHTTPErrorStatusCode {
                failInitialLoad()
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            isLoading?.wrappedValue = false

            guard let restrictedLoading, initialLoad == .loading else {
                return
            }

            initialLoad = .shown
            restrictedLoading.onFirstContent()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading?.wrappedValue = false
            failInitialLoad(after: error)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if restrictedLoading != nil, popupUrl == nil {
                webView.load(navigationAction.request)
                return nil
            }

            popupUrl?.wrappedValue = navigationAction.request.url
            return nil
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            failInitialLoad(after: error)

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

        private func refuse(_ url: URL) {
            AppLogger.info("Navigation to a page that isn't allowed is cancelled: \(url.host ?? "")")
            failInitialLoad()
        }

        private func failInitialLoad(after error: any Error) {
            let error = error as NSError

            guard error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled else {
                return
            }

            failInitialLoad()
        }

        private func failInitialLoad() {
            guard let restrictedLoading, initialLoad == .loading else {
                return
            }

            initialLoad = .failed
            restrictedLoading.onInitialLoadFailure()
        }
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
            restrictedLoading: restrictedLoading
        )
    }
}

// MARK: - RestrictedLoading

extension WebView {
    struct RestrictedLoading {
        let isAllowed: @MainActor (URL) -> Bool
        let onFirstContent: @MainActor () -> Void
        let onInitialLoadFailure: @MainActor () -> Void
    }
}

private extension WebView.Coordinator {
    enum InitialLoad {
        case loading
        case shown
        case failed
    }
}

private extension WebView {
    enum Constants {
        static let defaultWebViewTimeoutInterval: TimeInterval = 60
        static let fileURLScheme: String = "file"
        static let firstHTTPErrorStatusCode = 400
    }
}
