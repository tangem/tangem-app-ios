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
    @Environment(\.dismiss) private var dismiss

    @StateObject private var bridge = WebViewBridge()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            UsedeskWebView(html: viewModel.widgetHTML, bridge: bridge)
                .ignoresSafeArea(edges: .bottom)
        }
        .onReceive(viewModel.injectJSPublisher) { script in
            bridge.evaluate(script) { result, error in
                if let error {
                    AppLogger.error(error: error)
                } else {
                    AppLogger.debug("[SupportChat] JS injection result: \(result ?? "nil")")
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { viewModel.sendLogs() }) {
                if viewModel.isSendingLogs {
                    ProgressView()
                        .tint(Colors.Text.primary1)
                } else {
                    Image(systemName: "doc.text")
                        .foregroundColor(Colors.Text.primary1)
                }
            }
            .padding(.leading, 16)

            Spacer()

            Text(Localization.commonContactSupport)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(Colors.Text.primary1)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
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
}

// MARK: - WKWebView wrapper

private struct UsedeskWebView: UIViewRepresentable {
    let html: String
    let bridge: WebViewBridge

    func makeUIView(context: Context) -> WKWebView {
        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 0

        let safeAreaScript = """
        document.documentElement.style.setProperty('--safe-bottom', '\(bottomInset)px');
        """

        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(
            WKUserScript(source: safeAreaScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.loadHTMLString(html, baseURL: URL(string: "https://tangem.com"))
        bridge.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Previews

#if DEBUG
struct SupportChatView_Previews: PreviewProvider {
    static var previews: some View {
        SupportChatView(
            viewModel: SupportChatViewModel(
                input: SupportChatInputModel(
                    logsComposer: LogsComposer(infoProvider: BaseDataCollector())
                )
            )
        )
    }
}
#endif // DEBUG
