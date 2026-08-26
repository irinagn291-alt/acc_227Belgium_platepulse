import Foundation

enum FoodErr: Error, Sendable, Equatable {
    case net
    case notFound
    case decode
}

struct FlexNum: Decodable, Sendable {
    let val: Double?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            val = nil
            return
        }
        if let d = try? c.decode(Double.self) {
            val = d
            return
        }
        if let i = try? c.decode(Int.self) {
            val = Double(i)
            return
        }
        if let s = try? c.decode(String.self) {
            val = Double(s.replacingOccurrences(of: ",", with: "."))
            return
        }
        val = nil
    }
}

struct NutrDTO: Decodable, Sendable {
    let energyKcal: FlexNum?
    let energy: FlexNum?
    let proteins: FlexNum?
    let carbs: FlexNum?
    let fat: FlexNum?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case energy = "energy_100g"
        case proteins = "proteins_100g"
        case carbs = "carbohydrates_100g"
        case fat = "fat_100g"
    }
}

struct ProdDTO: Decodable, Sendable {
    let code: String?
    let productName: String?
    let genericName: String?
    let brands: String?
    let imageURL: String?
    let imageSmallURL: String?
    let nutriments: NutrDTO?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case genericName = "generic_name"
        case brands
        case imageURL = "image_url"
        case imageSmallURL = "image_small_url"
        case nutriments
    }

    func asFood() -> FoodItem? {
        let rawName = productName ?? genericName ?? brands ?? ""
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let code = (self.code ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return nil }
        let n = nutriments
        let kcal = PortionMath.kcal100(kcal: n?.energyKcal?.val, kj: n?.energy?.val)
        return FoodItem(
            code: code,
            name: name,
            brand: (brands ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            kcal100: kcal,
            prot100: n?.proteins?.val,
            carb100: n?.carbs?.val,
            fat100: n?.fat?.val,
            imgURL: imageSmallURL ?? imageURL,
            shelfImg: nil,
            refreshed: Date()
        )
    }
}

struct SrchDTO: Decodable, Sendable {
    let products: [ProdDTO]?
}

struct ProdWrapDTO: Decodable, Sendable {
    let status: Int?
    let product: ProdDTO?
}

/// Owns both Open Food Facts endpoints.
actor FoodSvc {
    private let sess: URLSession
    private let ua = "PlatePulse/1.0 (iOS; +https://platepulse.pro)"

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 15
        cfg.httpAdditionalHeaders = ["User-Agent": ua]
        sess = URLSession(configuration: cfg)
    }

    func search(_ query: String) async throws -> [FoodItem] {
        var parts = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        parts?.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "18")
        ]
        guard let url = parts?.url else { throw FoodErr.net }
        let data = try await pull(url)
        let dto: SrchDTO
        do {
            dto = try JSONDecoder().decode(SrchDTO.self, from: data)
        } catch {
            throw FoodErr.decode
        }
        return (dto.products ?? []).compactMap { $0.asFood() }
    }

    func product(_ code: String) async throws -> FoodItem {
        let cands = CodeNorm.cands(code)
        let list = cands.isEmpty ? [code] : cands
        var last: FoodErr = .notFound
        for c in list {
            do {
                return try await one(c)
            } catch let e as FoodErr {
                last = e
            }
        }
        if let shelf = ShelfStore.byCode(CodeNorm.pad(list[0])) ?? list.compactMap(ShelfStore.byCode).first {
            return shelf
        }
        throw last
    }

    private func one(_ code: String) async throws -> FoodItem {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json") else {
            throw FoodErr.net
        }
        let data = try await pull(url)
        let wrap: ProdWrapDTO
        do {
            wrap = try JSONDecoder().decode(ProdWrapDTO.self, from: data)
        } catch {
            throw FoodErr.decode
        }
        if wrap.status == 0 { throw FoodErr.notFound }
        guard let item = wrap.product?.asFood() else { throw FoodErr.notFound }
        return item
    }

    private func pull(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15
        do {
            return try await fire(req)
        } catch let e as FoodErr {
            if e == .notFound || Task.isCancelled { throw e }
            return try await fire(req)
        }
    }

    private func fire(_ req: URLRequest) async throws -> Data {
        do {
            let (data, resp) = try await sess.data(for: req)
            if let http = resp as? HTTPURLResponse {
                if http.statusCode == 404 { throw FoodErr.notFound }
                if !(200...299).contains(http.statusCode) { throw FoodErr.net }
            }
            return data
        } catch let e as FoodErr {
            throw e
        } catch {
            throw FoodErr.net
        }
    }
}
