import SwiftUI

/// 앱의 네비게이션을 관리하는 Router
@MainActor
final class AppRouter: ObservableObject {

    // MARK: - Properties

    /// NavigationStack의 경로
    @Published var path = NavigationPath()

    // MARK: - Navigation Methods

    /// 저장소 상세 WebView로 이동
    /// - Parameter url: 저장소 HTML URL
    func showDetail(url: URL) {
        path.append(AppRoute.repositoryDetail(url: url))
    }

    /// 이전 화면으로 돌아가기
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 루트 화면으로 이동
    func popToRoot() {
        path.removeLast(path.count)
    }
}
