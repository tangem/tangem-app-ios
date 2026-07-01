//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import WebKit
import TangemLocalization
import TangemUI
import TangemAssets

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel

    @StateObject private var bridge = WebViewBridge()

    var body: some View {
        webViewContent
            .navigationBarTitle(Localization.supportChatScreenTitle, displayMode: .inline)
            .navigationBarItems(trailing: navBarMenu)
            .onReceive(viewModel.injectJSPublisher) { script in
                bridge.evaluate(script) { result, error in
                    if let error {
                        SupportChatLogger.error(error: error)
                    } else {
                        SupportChatLogger.debug("JS injection result: \(result ?? "nil")")
                    }
                }
            }
            .onReceive(viewModel.reloadPublisher) {
                SupportChatLogger.debug("Reloading widget after load timeout")
                bridge.reload(html: viewModel.widgetHTML)
            }
            .onDisappear {
                viewModel.onClose()
            }
    }

    private var webViewContent: some View {
        ZStack {
            WebView(
                htmlString: viewModel.widgetHTML,
                baseURL: UsedeskWebViewConstants.baseURL,
                allowsJavaScript: true,
                validatesCertificateTransparency: true,
                messageHandlers: [
                    "chatReady": { _ in viewModel.markChatReady() },
                    "saveToken": { body in
                        if let token = body as? String { viewModel.saveSessionToken(token) }
                    },
                    "reloadForMessage": { _ in bridge.reload(html: viewModel.widgetHTML) },
                ],
                onMakeWebView: { bridge.webView = $0 }
            )

            switch viewModel.loadState {
            case .loading:
                Color.white
                ActivityIndicatorView(style: .large, color: .tangemGrayDark)
            case .failure:
                Color.white
                Text(Localization.commonSomethingWentWrong)
                    .style(Fonts.Regular.body, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            case .success:
                EmptyView()
            }
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }

    private var navBarMenu: some View {
        Menu {
            Button(action: { viewModel.sendLogs() }) {
                Label(Localization.supportChatShareLogsButton, systemImage: "doc.text")
            }
            .disabled(viewModel.isSendingLogs)
        } label: {
            if viewModel.isSendingLogs {
                ActivityIndicatorView(style: .medium, color: UIColor(Colors.Text.primary1))
            } else {
                Image(systemName: "ellipsis")
                    .foregroundColor(Colors.Text.primary1)
            }
        }
        .disabled(viewModel.isSendingLogs)
    }
}

// MARK: - WebView bridge

/// Holds a weak reference to the underlying WKWebView so the ViewModel's JS snippets
/// can be evaluated after the view has been set up.
private class WebViewBridge: ObservableObject {
    weak var webView: WKWebView?

    func evaluate(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        webView?.evaluateJavaScript(script, completionHandler: completion)
    }

    func reload(html: String) {
        // loadHTMLString (not reload()) — the widget is loaded from an inline string, not a URL.
        webView?.loadHTMLString(html, baseURL: UsedeskWebViewConstants.baseURL)
    }
}

private enum UsedeskWebViewConstants {
    static let baseURL = URL(string: "https://tangem.com/ios-agent/")
}

// MARK: - Previews

#if DEBUG
struct SupportChatView_Previews: PreviewProvider {
    static var previews: some View {
        SupportChatView(
            viewModel: SupportChatViewModel(
                input: SupportChatInputModel(
                    logsComposer: LogsComposer(infoProvider: BaseDataCollector()),
                    userIdentifier: nil,
                    source: .settings
                )
            )
        )
    }
}
#endif // DEBUG
