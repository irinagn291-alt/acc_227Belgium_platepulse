import UIKit

/// Three-tier thumbnail: remote, shelf asset, placeholder.
@MainActor
final class ImgLoad {
    private var mem: [String: UIImage] = [:]

    func thumb(url: String?, shelf: String?) async -> UIImage {
        if let url, let hit = mem[url] { return hit }
        if let url, let remote = await fetch(url) {
            mem[url] = remote
            return remote
        }
        if let shelf, let img = UIImage(named: shelf) { return img }
        return UIImage(named: "plp_ProductPlaceholder") ?? UIImage()
    }

    private func fetch(_ urlStr: String) async -> UIImage? {
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
