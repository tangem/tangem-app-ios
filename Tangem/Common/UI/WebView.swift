//
//  SafariView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

struct WebViewContainerViewModel: Identifiable {
    let id = UUID()
    var url: URL?
    var title: String
    var addLoadingIndicator = false
    var withCloseButton = false
    var withNavigationBar: Bool = true
    var urlActions: [String: ((String) -> Void)] = [:]
    var contentInset: UIEdgeInsets? = nil
}

struct WebViewContainer: View {
    let viewModel: WebViewContainerViewModel

    @State private var popupUrl: URL?
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading: Bool = true

    private var webViewContent: some View {
        WebView(url: viewModel.url,
                popupUrl: $popupUrl,
                urlActions: viewModel.urlActions,
                isLoading: $isLoading,
                contentInset: viewModel.contentInset)
    }

    private var content: some View {
        ZStack {
            if viewModel.withNavigationBar {
                webViewContent
                    .navigationBarTitle(Text(viewModel.title), displayMode: .inline)
                    .background(Color.tangemBg.edgesIgnoringSafeArea(.all))
            } else {
                webViewContent
            }

            if isLoading && viewModel.addLoadingIndicator {
                ActivityIndicatorView(color: .tangemGrayDark)
            }
        }
    }

    var body: some View {
        VStack {
            if viewModel.withCloseButton {
                NavigationView {
                    content
                        .navigationBarItems(leading:
                            Button("common_close") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .animation(nil)
                        )
                }
            } else {
                content
            }

        }
        .sheet(item: $popupUrl) { popupUrl in
            NavigationView {
                WebView(url: popupUrl, popupUrl: .constant(nil), isLoading: .constant(false))
                    .navigationBarTitle("", displayMode: .inline)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    var url: URL?
    var popupUrl: Binding<URL?>
    var urlActions: [String: ((String) -> Void)] = [:]
    var isLoading:  Binding<Bool>
    var contentInset: UIEdgeInsets?

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        if let url = url {
            print("Loading request with url: \(url)")
            view.load(URLRequest(url: url))
        }
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        if let contentInset {
            view.scrollView.contentInset = contentInset
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let urlActions: [String: ((String) -> Void)]
        var popupUrl: Binding<URL?>
        var isLoading:  Binding<Bool>

        init(urlActions: [String: ((String) -> Void)] = [:], popupUrl: Binding<URL?>, isLoading: Binding<Bool>) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("decide for url \(String(describing: navigationAction.request.url?.absoluteString))")
            if let url = navigationAction.request.url?.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel)
                actionForURL(navigationAction.request.url!.absoluteString)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            isLoading.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading.wrappedValue = false
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            popupUrl.wrappedValue = navigationAction.request.url
            return nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(urlActions: urlActions, popupUrl: self.popupUrl, isLoading: self.isLoading)
    }
}
