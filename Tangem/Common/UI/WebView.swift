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


struct WebViewContainer: View {
    var url: URL?
    @State var popupUrl: URL?
    //    var closeUrl: String? = nil
    var title: LocalizedStringKey
    var addLoadingIndicator = false
    var withCloseButton = false
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading: Bool = true
    
    var urlActions: [String : ((String) -> Void)] = [:]
    //    {
    //        if let closeUrl = closeUrl {
    //            return [closeUrl: {
    //                self.presentationMode.wrappedValue.dismiss()
    //            }]
    //        } else {
    //            return [:]
    //        }
    //    }
    
    private var content: some View {
        ZStack {
            WebView(url: url, popupUrl: $popupUrl, urlActions: urlActions, isLoading: $isLoading)
                .navigationBarTitle(title, displayMode: .inline)
                .background(Color.tangemBg.edgesIgnoringSafeArea(.all))
            if isLoading && addLoadingIndicator {
                ActivityIndicatorView(color: .tangemGrayDark)
            }
        }
    }
    
    var body: some View {
        VStack {
            if withCloseButton {
                NavigationView {
                    content
                        .navigationBarItems(leading:
                            Button("common_close") {
                                presentationMode.wrappedValue.dismiss()
                            }
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
    var urlActions: [String : ((String) -> Void)] = [:]
    var isLoading:  Binding<Bool>
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let view =  WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        if let url = url {
            print("Loading request with url: \(url)")
            view.load(URLRequest(url: url))
        }
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let urlActions: [String: ((String) -> Void)]
        var popupUrl: Binding<URL?>
        var isLoading:  Binding<Bool>
        
        init(urlActions: [String : ((String) -> Void)] = [:], popupUrl: Binding<URL?>, isLoading: Binding<Bool>) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
