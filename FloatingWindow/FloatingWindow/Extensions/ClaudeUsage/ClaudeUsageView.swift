import SwiftUI
import WebKit

struct ClaudeUsageView: View {
    @StateObject private var webState = WebViewState()

    var body: some View {
        if let url = URL(string: "https://claude.ai/settings/usage") {
            ZStack(alignment: .topTrailing) {
                WebView(url: url, state: webState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: { webState.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
    }
}

@MainActor
class WebViewState: ObservableObject {
    weak var webView: WKWebView?

    func reload() {
        guard let webView, let url = URL(string: "https://claude.ai/settings/usage") else { return }
        webView.load(URLRequest(url: url))
    }
}

struct WebView: NSViewRepresentable {
    let url: URL
    let state: WebViewState

    private static let allowedDomains = [
        "claude.ai",
        "anthropic.com",
        "stripe.com",
    ]

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        context.coordinator.targetURL = url
        state.webView = webView
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var targetURL: URL?

        private func isAllowedDomain(_ host: String) -> Bool {
            return WebView.allowedDomains.contains { host == $0 || host.hasSuffix(".\($0)") }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                let host = url.host ?? ""
                if isAllowedDomain(host) {
                    // Silently ignore allowed-domain popups (e.g. Stripe iframes)
                    // — don't load them into the main webview
                } else if navigationAction.navigationType == .linkActivated {
                    // Only open system browser for user-clicked links
                    NSWorkspace.shared.open(url)
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, let host = url.host else {
                decisionHandler(.allow)
                return
            }

            if isAllowedDomain(host) {
                decisionHandler(.allow)
            } else if navigationAction.navigationType == .linkActivated {
                // Only open system browser for user-clicked links
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                // Silently block background requests to unknown domains
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let currentURL = webView.url,
                  let host = currentURL.host,
                  host.contains("claude.ai") else { return }

            let path = currentURL.path
            if !path.contains("settings") && !path.contains("login") {
                if let target = targetURL {
                    webView.load(URLRequest(url: target))
                    return
                }
            }

            // Scroll to the "Plan usage limits" section
            if path.contains("settings/usage") {
                scrollToUsageSection(webView)
            }
        }

        private func scrollToUsageSection(_ webView: WKWebView) {
            let js = """
            (function() {
                var headings = document.querySelectorAll('h2, h3, h4, [class*="heading"], [class*="title"]');
                for (var h of headings) {
                    if (h.textContent.includes('Plan usage')) {
                        h.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        return;
                    }
                }
                // Fallback: look for any element containing "Plan usage"
                var all = document.querySelectorAll('*');
                for (var el of all) {
                    if (el.children.length === 0 && el.textContent.trim().startsWith('Plan usage')) {
                        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        return;
                    }
                }
            })();
            """
            // Small delay to let the page render
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                webView.evaluateJavaScript(js)
            }
        }
    }
}
