import SwiftUI
import WebKit

/// Q1 iOS chrome: address bar + navigation buttons over the WKWebView host.
/// Minimal by design — the shell owns rules-enforcement UI, AI assist,
/// preloads and identity; nothing else.
struct ContentView: View {

    private let bridge = Bridge()

    @State private var address = BrowserWebView.startPage.absoluteString
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var webView: WKWebView?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            BrowserWebView(
                bridge: bridge,
                onCreated: { self.webView = $0 },
                onNavigation: { webView in
                    address = webView.url?.absoluteString ?? ""
                    canGoBack = webView.canGoBack
                    canGoForward = webView.canGoForward
                    isLoading = webView.isLoading
                }
            )
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: { webView?.goBack() }) {
                Image(systemName: "chevron.backward")
            }
            .disabled(!canGoBack)

            Button(action: { webView?.goForward() }) {
                Image(systemName: "chevron.forward")
            }
            .disabled(!canGoForward)

            Button(action: { webView?.reload() }) {
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
            }

            TextField("Enter address", text: $address)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(loadAddress)

            Button(action: loadAddress) {
                Image(systemName: "arrow.up")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }

    private func loadAddress() {
        guard let url = BrowserWebView.makeURL(from: address) else { return }
        webView?.load(URLRequest(url: url))
    }
}

#Preview {
    ContentView()
}
