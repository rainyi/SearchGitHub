import SwiftUI

struct RepositoryWebView: View {
    let url: URL

    var body: some View {
        #if os(iOS)
        WebView(url: url)
            .navigationTitle("저장소 상세")
            .navigationBarTitleDisplayMode(.inline)
        #else
        // macOS fallback - Safari로 열기
        Text("URL: \(url.absoluteString)")
            .navigationTitle("저장소 상세")
        #endif
    }
}

// MARK: - WebView Representable (iOS only)

#if os(iOS)
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif

// MARK: - Preview

#Preview {
    NavigationStack {
        RepositoryWebView(url: URL(string: "https://github.com/apple/swift")!)
    }
}
