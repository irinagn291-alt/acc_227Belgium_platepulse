import Foundation

struct EntryDoc: Codable, Sendable {
    var schemaVersion: Int
    var items: [DayEntry]

    static let empty = EntryDoc(schemaVersion: 1, items: [])

    init(schemaVersion: Int, items: [DayEntry]) {
        self.schemaVersion = schemaVersion
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CK.self)
        let v = try c.decode(Int.self, forKey: .schemaVersion)
        switch v {
        case 1:
            schemaVersion = 1
            items = try c.decode([DayEntry].self, forKey: .items)
        default:
            schemaVersion = 1
            items = try c.decodeIfPresent([DayEntry].self, forKey: .items) ?? []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(items, forKey: .items)
    }

    private enum CK: String, CodingKey { case schemaVersion, items }
}

struct TgtDoc: Codable, Sendable {
    var schemaVersion: Int
    var tgt: GoalTgt
    var onboarded: Bool

    static let empty = TgtDoc(schemaVersion: 1, tgt: .seed, onboarded: false)

    init(schemaVersion: Int, tgt: GoalTgt, onboarded: Bool) {
        self.schemaVersion = schemaVersion
        self.tgt = tgt
        self.onboarded = onboarded
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CK.self)
        let v = try c.decode(Int.self, forKey: .schemaVersion)
        switch v {
        case 1:
            schemaVersion = 1
            tgt = try c.decode(GoalTgt.self, forKey: .tgt)
            onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        default:
            schemaVersion = 1
            tgt = try c.decodeIfPresent(GoalTgt.self, forKey: .tgt) ?? .seed
            onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(tgt, forKey: .tgt)
        try c.encode(onboarded, forKey: .onboarded)
    }

    private enum CK: String, CodingKey { case schemaVersion, tgt, onboarded }
}

struct WishDoc: Codable, Sendable {
    var schemaVersion: Int
    var items: [WishRec]

    static let empty = WishDoc(schemaVersion: 1, items: [])

    init(schemaVersion: Int, items: [WishRec]) {
        self.schemaVersion = schemaVersion
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CK.self)
        let v = try c.decode(Int.self, forKey: .schemaVersion)
        switch v {
        case 1:
            schemaVersion = 1
            items = try c.decode([WishRec].self, forKey: .items)
        default:
            schemaVersion = 1
            items = try c.decodeIfPresent([WishRec].self, forKey: .items) ?? []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(items, forKey: .items)
    }

    private enum CK: String, CodingKey { case schemaVersion, items }
}

struct A11yDoc: Codable, Sendable {
    var schemaVersion: Int
    var prefs: A11yPrefs

    static let empty = A11yDoc(schemaVersion: 1, prefs: .seed)

    init(schemaVersion: Int, prefs: A11yPrefs) {
        self.schemaVersion = schemaVersion
        self.prefs = prefs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CK.self)
        let v = try c.decode(Int.self, forKey: .schemaVersion)
        switch v {
        case 1:
            schemaVersion = 1
            prefs = try c.decode(A11yPrefs.self, forKey: .prefs)
        default:
            schemaVersion = 1
            prefs = try c.decodeIfPresent(A11yPrefs.self, forKey: .prefs) ?? .seed
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(prefs, forKey: .prefs)
    }

    private enum CK: String, CodingKey { case schemaVersion, prefs }
}

struct CacheDoc: Codable, Sendable {
    var schemaVersion: Int
    var items: [FoodItem]

    static let empty = CacheDoc(schemaVersion: 1, items: [])

    init(schemaVersion: Int, items: [FoodItem]) {
        self.schemaVersion = schemaVersion
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CK.self)
        let v = try c.decode(Int.self, forKey: .schemaVersion)
        switch v {
        case 1:
            schemaVersion = 1
            items = try c.decode([FoodItem].self, forKey: .items)
        default:
            schemaVersion = 1
            items = try c.decodeIfPresent([FoodItem].self, forKey: .items) ?? []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CK.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(items, forKey: .items)
    }

    private enum CK: String, CodingKey { case schemaVersion, items }
}

/// Persistence seam. Memory is source of truth; plists are a projection.
actor PulseMgr {
    private var entries: [DayEntry] = []
    private var targets: GoalTgt = .seed
    private var wishes: [WishRec] = []
    private var a11y: A11yPrefs = .seed
    private var cache: [String: FoodItem] = [:]
    private var onboarded = false
    private var notice: String?
    private var writeTask: Task<Void, Never>?
    private let root: URL
    private let cacheDir: URL
    private let enc = PropertyListEncoder()
    private let dec = PropertyListDecoder()

    init(root: URL? = nil, cacheDir: URL? = nil) {
        let fm = FileManager.default
        if let root {
            self.root = root
        } else {
            let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fm.temporaryDirectory
            self.root = base.appendingPathComponent("PlatePulse", isDirectory: true)
        }
        if let cacheDir {
            self.cacheDir = cacheDir
        } else {
            let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fm.temporaryDirectory
            self.cacheDir = base.appendingPathComponent("PlatePulse", isDirectory: true)
        }
        enc.outputFormat = .xml
    }

    func boot() async -> String? {
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        var vals = URLResourceValues()
        vals.isExcludedFromBackup = true
        var cacheURL = cacheDir
        try? cacheURL.setResourceValues(vals)

        let eDoc: EntryDoc = load("entries.plist", empty: .empty, in: root)
        let tDoc: TgtDoc = load("targets.plist", empty: .empty, in: root)
        let wDoc: WishDoc = load("wishlist.plist", empty: .empty, in: root)
        let aDoc: A11yDoc = load("a11y.plist", empty: .empty, in: root)
        let cDoc: CacheDoc = load("foodcache.plist", empty: .empty, in: cacheDir)
        entries = eDoc.items
        targets = tDoc.tgt
        onboarded = tDoc.onboarded
        wishes = wDoc.items
        a11y = aDoc.prefs
        cache = Dictionary(uniqueKeysWithValues: cDoc.items.map { ($0.code, $0) })
        seedDemoIfNeeded()
        return notice
    }

    func flush() async {
        writeTask?.cancel()
        writeTask = nil
        persistAll()
    }

    func resetAllData() async {
        entries = []
        targets = .seed
        wishes = []
        a11y = .seed
        persistAll()
    }

    func allEntries() -> [DayEntry] { entries }
    func tgt() -> GoalTgt { targets }
    func allWishes() -> [WishRec] { wishes }
    func prefs() -> A11yPrefs { a11y }
    func isOnboarded() -> Bool { onboarded }
    func cached(_ code: String) -> FoodItem? { cache[code] }

    func dayRows(_ key: DayKey, eaten: Bool?) -> [DayEntry] {
        entries.filter { row in
            row.day == key && (eaten == nil || row.eaten == eaten)
        }
    }

    func planRows(horizon: Int) -> [DayEntry] {
        let start = DayKey.today().shift(1)
        let end = DayKey.today().shift(horizon)
        return entries.filter { row in
            !row.eaten && row.day.date() >= start.date() && row.day.date() <= end.date()
        }
    }

    func addEntry(_ row: DayEntry) async {
        entries.append(row)
        persistNow()
    }

    func dropEntry(_ id: UUID) async {
        entries.removeAll { $0.id == id }
        persistNow()
    }

    func eatPlanned(_ id: UUID) async {
        if let i = entries.firstIndex(where: { $0.id == id }) {
            entries[i].eaten = true
            entries[i].day = DayKey.today()
            persistNow()
        }
    }

    func setTgt(_ t: GoalTgt) async {
        targets = t
        markDirty()
    }

    func finishOnb(_ t: GoalTgt) async {
        targets = t
        onboarded = true
        persistNow()
    }

    func reopenOnb() async {
        onboarded = false
        persistNow()
    }

    func setA11y(_ p: A11yPrefs) async {
        a11y = p
        persistNow()
    }

    @discardableResult
    func addWish(_ item: FoodItem) async -> Bool {
        if let i = wishes.firstIndex(where: { $0.code == item.code }) {
            var rec = WishRec.from(item)
            rec.id = wishes[i].id
            wishes[i] = rec
            persistNow()
            return false
        }
        wishes.append(WishRec.from(item))
        persistNow()
        return true
    }

    func hasWish(_ code: String) -> Bool {
        wishes.contains { $0.code == code }
    }

    func dropWish(_ id: UUID) async {
        wishes.removeAll { $0.id == id }
        persistNow()
    }

    func putFood(_ item: FoodItem) async {
        cache[item.code] = item
        markDirty()
    }

    private func seedDemoIfNeeded() {
        #if targetEnvironment(simulator)
        let key = "plp.demo.v1"
        if UserDefaults.standard.bool(forKey: key) { return }
        let today = DayKey.today()
        if let hummus = ShelfStore.byCode("0074354611200") {
            entries.append(DayEntry.make(item: hummus, grams: 80, slot: .dawn, day: today, eaten: true))
        }
        if let beans = ShelfStore.byCode("0041303001943") {
            entries.append(DayEntry.make(item: beans, grams: 150, slot: .noon, day: today, eaten: true))
        }
        if let tea = ShelfStore.byCode("0037000388401") {
            entries.append(DayEntry.make(item: tea, grams: 250, slot: .interval, day: today, eaten: true))
        }
        if let loaf = ShelfStore.byCode("5000168001012") {
            entries.append(DayEntry.make(item: loaf, grams: 60, slot: .dusk, day: today.shift(1), eaten: false))
        }
        onboarded = true
        UserDefaults.standard.set(true, forKey: key)
        persistNow()
        #endif
    }

    private func markDirty() {
        writeTask?.cancel()
        writeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.persistAll()
        }
    }

    private func persistNow() {
        writeTask?.cancel()
        writeTask = nil
        persistAll()
    }

    private func persistAll() {
        write(EntryDoc(schemaVersion: 1, items: entries), name: "entries.plist", in: root)
        write(TgtDoc(schemaVersion: 1, tgt: targets, onboarded: onboarded), name: "targets.plist", in: root)
        write(WishDoc(schemaVersion: 1, items: wishes), name: "wishlist.plist", in: root)
        write(A11yDoc(schemaVersion: 1, prefs: a11y), name: "a11y.plist", in: root)
        write(CacheDoc(schemaVersion: 1, items: Array(cache.values)), name: "foodcache.plist", in: cacheDir)
    }

    private func load<T: Decodable>(_ name: String, empty: T, in dir: URL) -> T {
        let url = dir.appendingPathComponent(name)
        let bak = url.appendingPathExtension("backup")
        if let data = try? Data(contentsOf: url) {
            do {
                return try dec.decode(T.self, from: data)
            } catch {
                if let b = try? Data(contentsOf: bak), let rec = try? dec.decode(T.self, from: b) {
                    notice = "A reading file was repaired from backup."
                    return rec
                }
                notice = "A reading file was reset after damage."
                return empty
            }
        }
        return empty
    }

    private func write<T: Encodable>(_ value: T, name: String, in dir: URL) {
        let url = dir.appendingPathComponent(name)
        let bak = url.appendingPathExtension("backup")
        do {
            let data = try enc.encode(value)
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: bak)
                try? FileManager.default.copyItem(at: url, to: bak)
            }
            try data.write(to: url, options: .atomic)
        } catch {
            notice = "A reading could not be saved just now."
        }
    }
}
