//
//  TangemPayKYCViewController.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemFoundation
import TangemVisa
import UIKit
import WebKit

final class TangemPayKYCViewController: UIViewController {
    private let accessToken: String
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let onClose: () -> Void

    private var shouldInitialize = true

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        contentController.add(self, name: messageName)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        return webView
    }()

    private var closeIcon: UIImage {
        Assets.Glyphs.cross20ButtonNew.uiImage
            .withCircleBackground(
                circleSize: 36,
                iconSize: 20,
                circleColor: UIColor(Colors.Button.secondary),
                iconColor: UIColor(Colors.Icon.informative)
            )
    }

    init(
        accessToken: String,
        customerInfoManagementService: any CustomerInfoManagementService,
        onClose: @escaping () -> Void
    ) {
        self.accessToken = accessToken
        self.customerInfoManagementService = customerInfoManagementService
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)

        setupLayout()
        loadSumSubSDK()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: closeIcon,
            style: .plain,
            target: self,
            action: #selector(close)
        )
    }

    @objc
    private func close() {
        navigationController?.dismiss(animated: true, completion: onClose)
    }

    private func loadSumSubSDK() {
        let eventsEnumerationString = TangemPayKYCStatusUpdateType.allCases
            .map { "'\($0.rawValue)'" }
            .joined(separator: ", ")

        webView.loadHTMLString(
            makeHTML(eventsArray: "[\(eventsEnumerationString)]"),
            baseURL: URL(string: "https://localhost") // Use localhost URL as baseURL to enable getUserMedia in WebView
        )
    }

    private func handleTokenRefresh() {
        runTask(in: self) { controller in
            let scriptForEvaluation: String
            do {
                let response = try await controller.customerInfoManagementService.loadKYCAccessToken()
                scriptForEvaluation = controller.makeResolveTokenScript(token: response.token)
            } catch {
                // [REDACTED_TODO_COMMENT]
                scriptForEvaluation = controller.makeRejectTokenScript(errorMessage: "Failed to fetch new token")
            }

            _ = try? await controller.webView.evaluateJavaScript(scriptForEvaluation)
        }
    }
}

extension TangemPayKYCViewController {
    var embeddedIntoNavigationController: UINavigationController {
        let navController = UINavigationController(rootViewController: self)
        navController.modalPresentationStyle = .overFullScreen
        return navController
    }
}

// MARK: - WKNavigationDelegate

extension TangemPayKYCViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard shouldInitialize else { return }

        shouldInitialize = false
        webView.evaluateJavaScript(makeInitSumSubScript(token: accessToken))
    }
}

// MARK: - WKUIDelegate

extension TangemPayKYCViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}

// MARK: - WKScriptMessageHandler

extension TangemPayKYCViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == messageName,
              let messageBody = message.body as? [String: Any],
              let eventTypeString = messageBody[eventTypeKey] as? String,
              let eventType = TangemPayKYCEventType(rawValue: eventTypeString)
        else {
            return
        }

        switch eventType {
        case .tokenRefreshRequest:
            handleTokenRefresh()
        case .statusUpdate:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}

// MARK: - SumSub WebSDK

private extension TangemPayKYCViewController {
    var messageName: String {
        "kycHandler"
    }

    var eventTypeKey: String {
        "eventType"
    }

    var eventKey: String {
        "event"
    }

    var payloadKey: String {
        "payload"
    }

    func makeInitSumSubScript(token: String) -> String {
        "initSumsub('\(token)');"
    }

    func makeResolveTokenScript(token: String) -> String {
        "tokenResolver.resolve('\(token)');"
    }

    func makeRejectTokenScript(errorMessage: String) -> String {
        "tokenResolver.reject(new Error('\(errorMessage)'));"
    }

    func makeHTML(eventsArray: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <script src="https://static.sumsub.com/idensic/static/sns-websdk-builder.js"></script>
            <script>
                let tokenResolver = null;

                function requestToken() {
                    return new Promise((resolve, reject) => {
                        tokenResolver = { resolve, reject };
                        window.webkit.messageHandlers.\(messageName).postMessage({
                            \(eventTypeKey): '\(TangemPayKYCEventType.tokenRefreshRequest.rawValue)'
                        });
                    });
                }

                async function initSumsub(accessToken) {
                    if (!accessToken) {
                        accessToken = await requestToken();
                    }

                    let builder = snsWebSdk.init(accessToken, requestToken);

                    \(eventsArray).forEach(eventName => {
                        builder = builder.on('idCheck.' + eventName, (payload) => {
                            window.webkit.messageHandlers.\(messageName).postMessage({
                                \(eventTypeKey): '\(TangemPayKYCEventType.statusUpdate.rawValue)',
                                \(eventKey): eventName,
                                \(payloadKey): payload
                            });
                        });
                    });

                    builder.build().launch('#sumsub-websdk-container');
                }
            </script>
        </head>
        <body>
            <div id="sumsub-websdk-container"/>
        </body>
        </html>
        """
    }
}
