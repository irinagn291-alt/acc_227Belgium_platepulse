import Foundation

/// Barcode normalisation and candidate expansion.
enum CodeNorm {
    static func runs(_ raw: String) -> [String] {
        var cur = ""
        var out: [String] = []
        for ch in raw {
            if ch.isNumber {
                cur.append(ch)
            } else if !cur.isEmpty {
                if (8...14).contains(cur.count) { out.append(cur) }
                cur = ""
            }
        }
        if (8...14).contains(cur.count) { out.append(cur) }
        return out
    }

    static func pad(_ code: String) -> String {
        code.count == 12 ? "0" + code : code
    }

    static func padRun(_ raw: String) -> String? {
        guard let first = runs(raw).first else { return nil }
        return pad(first)
    }

    /// QR payloads are often an Open Food Facts / GS1 URL, not bare digits.
    static func qrCode(_ raw: String) -> String? {
        let trim = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trim), url.scheme != nil else { return nil }
        let keys: Set<String> = ["ean", "ean13", "ean_13", "gtin", "code", "barcode"]
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items {
                guard keys.contains(item.name.lowercased()), let value = item.value else { continue }
                if let code = padRun(value) { return code }
            }
        }
        let parts = url.pathComponents
        if let i = parts.firstIndex(where: { $0.caseInsensitiveCompare("product") == .orderedSame }),
           let next = parts[safe: i + 1],
           let code = padRun(next) {
            return code
        }
        return parts.reversed().compactMap(padRun).first
    }

    static func primary(_ raw: String) -> String? {
        qrCode(raw) ?? padRun(raw)
    }

    static func cands(_ raw: String) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        func add(_ s: String) {
            guard !s.isEmpty, seen.insert(s).inserted else { return }
            out.append(s)
        }
        if let q = qrCode(raw) {
            add(q)
            if q.count == 13, q.hasPrefix("0") { add(String(q.dropFirst())) }
        }
        for r in runs(raw) {
            add(pad(r))
            add(r)
            if let e = expandUPCE(r) {
                add(pad(e))
                add(e)
            }
        }
        return out
    }

    static func expandUPCE(_ code: String) -> String? {
        var digits = code
        if digits.count == 8 {
            // drop number system later; keep 8 including check
        } else if digits.count == 6 {
            digits = "0" + digits + "0"
        } else {
            return nil
        }
        guard digits.count == 8, digits.allSatisfy(\.isNumber) else { return nil }
        let ns = digits[digits.startIndex]
        guard ns == "0" || ns == "1" else { return nil }
        let body = digits.dropFirst().dropLast()
        guard body.count == 6 else { return nil }
        let x = Array(body)
        let last = x[5]
        let upc12: String
        switch last {
        case "0", "1", "2":
            upc12 = "\(ns)\(x[0])\(x[1])\(last)0000\(x[2])\(x[3])\(x[4])"
        case "3":
            upc12 = "\(ns)\(x[0])\(x[1])\(x[2])00000\(x[3])\(x[4])"
        case "4":
            upc12 = "\(ns)\(x[0])\(x[1])\(x[2])\(x[3])00000\(x[4])"
        default:
            upc12 = "\(ns)\(x[0])\(x[1])\(x[2])\(x[3])\(x[4])0000\(last)"
        }
        return upc12
    }
}
