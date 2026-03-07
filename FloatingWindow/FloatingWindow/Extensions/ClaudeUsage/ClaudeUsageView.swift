import SwiftUI
import WebKit

struct ClaudeUsageView: View {
    var body: some View {
        if let url = URL(string: "https://claude.ai/settings/usage") {
            WebView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct WebView: NSViewRepresentable {
    let url: URL

    /// Domains allowed to load inside the embedded WebView.
    private static let allowedDomains = [
        "claude.ai",
        "anthropic.com",
    ]

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        context.coordinator.targetURL = url
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var targetURL: URL?

        /// Check if a host is in the allowed domains list.
        private func isAllowedDomain(_ host: String) -> Bool {
            return WebView.allowedDomains.contains { host == $0 || host.hasSuffix(".\($0)") }
        }

        // Handle popup windows — only allow known domains, open everything else in system browser
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                let host = url.host ?? ""
                if isAllowedDomain(host) {
                    webView.load(URLRequest(url: url))
                } else {
                    NSWorkspace.shared.open(url)
                }
            }
            return nil
        }

        // Restrict all navigation to allowed domains — open everything else in system browser
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, let host = url.host else {
                decisionHandler(.allow)
                return
            }

            if isAllowedDomain(host) {
                decisionHandler(.allow)
            } else {
                // OAuth and any other external URLs open in system browser
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let currentURL = webView.url,
                  let host = currentURL.host,
                  host.contains("claude.ai") else { return }

            // After login, Claude redirects to home — navigate back to usage page
            let path = currentURL.path
            if !path.contains("settings") && !path.contains("login") {
                if let target = targetURL {
                    webView.load(URLRequest(url: target))
                    return
                }
            }
        }
    }
}
