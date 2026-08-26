import XCTest
@testable import PlatePulse

final class PortionTests: XCTestCase {
    func testKcalDirect() {
        XCTAssertEqual(PortionMath.kcal100(kcal: 166, kj: 700), 166)
    }

    func testKjFallback() {
        let v = PortionMath.kcal100(kcal: nil, kj: 418.4)
        XCTAssertEqual(v ?? 0, 100, accuracy: 0.01)
    }

    func testPortionScale() {
        XCTAssertEqual(PortionMath.part(166, 80) ?? -1, 132.8, accuracy: 0.0001)
        XCTAssertNil(PortionMath.part(nil, 80))
    }
}

final class CodeNormTests: XCTestCase {
    func testEAN8() {
        XCTAssertEqual(CodeNorm.primary("40123455"), "40123455")
    }

    func testEAN13() {
        XCTAssertEqual(CodeNorm.primary("5000168001012"), "5000168001012")
    }

    func testUPCAPad() {
        XCTAssertEqual(CodeNorm.primary("012345678905"), "0012345678905")
    }

    func testURLInput() {
        let url = "https://world.openfoodfacts.org/product/737628064502/thai-peanut"
        XCTAssertEqual(CodeNorm.primary(url), "0737628064502")
    }

    func testNoDigitRun() {
        XCTAssertNil(CodeNorm.primary("no-code-here"))
        XCTAssertTrue(CodeNorm.cands("abc").isEmpty)
    }
}

final class MacroTests: XCTestCase {
    func testUnknownStaysUnknown() {
        let item = FoodItem(
            code: "1", name: "X", brand: "", kcal100: 10, prot100: nil, carb100: nil, fat100: nil,
            imgURL: nil, shelfImg: nil, refreshed: Date()
        )
        let row = DayEntry.make(item: item, grams: 50, slot: .dawn, day: DayKey.today(), eaten: true)
        XCTAssertNil(row.prot)
        XCTAssertNil(row.carb)
        XCTAssertNil(row.fat)
        XCTAssertEqual(row.kcal ?? -1, 5, accuracy: 0.0001)
        XCTAssertNotEqual(row.prot ?? -1, 0)
    }
}

final class DayAggTests: XCTestCase {
    func testAllFourSlots() {
        let day = DayKey(year: 2026, month: 8, day: 25)
        func row(_ slot: SlotKind, kcal: Double, prot: Double?) -> DayEntry {
            DayEntry(
                id: UUID(), code: slot.rawValue, name: slot.title, brand: "", grams: 100,
                kcal100: kcal, prot100: prot, carb100: 1, fat100: 1,
                slot: slot, day: day, eaten: true, imgURL: nil, shelfImg: nil
            )
        }
        let tot = DayAgg.sum([
            row(.dawn, kcal: 100, prot: 2),
            row(.noon, kcal: 200, prot: 3),
            row(.dusk, kcal: 50, prot: nil),
            row(.interval, kcal: 10, prot: 1)
        ])
        XCTAssertEqual(tot.kcal, 360, accuracy: 0.001)
        XCTAssertEqual(tot.prot ?? 0, 6, accuracy: 0.001)
        XCTAssertEqual(tot.carb ?? 0, 4, accuracy: 0.001)
    }
}

final class WishTests: XCTestCase {
    func testDuplicateUpdates() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let mgr = PulseMgr(root: dir, cacheDir: dir.appendingPathComponent("c"))
        _ = await mgr.boot()
        var a = ShelfStore.all[0]
        a.name = "First"
        var b = a
        b.name = "Second"
        let first = await mgr.addWish(a)
        let second = await mgr.addWish(b)
        XCTAssertTrue(first)
        XCTAssertFalse(second)
        let all = await mgr.allWishes()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].name, "Second")
        XCTAssertEqual(all[0].code, a.code)
    }
}

final class DayKeyTests: XCTestCase {
    func testDSTSpringForward() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let early = cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 0, minute: 30))
        let late = cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3, minute: 30))
        let next = cal.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0, minute: 15))
        XCTAssertNotNil(early)
        XCTAssertNotNil(late)
        XCTAssertNotNil(next)
        if let early, let late, let next {
            XCTAssertEqual(DayKey(early, cal: cal), DayKey(late, cal: cal))
            XCTAssertNotEqual(DayKey(early, cal: cal), DayKey(next, cal: cal))
            XCTAssertEqual(DayKey(early, cal: cal).dateComps.day, 8)
        }
    }
}

final class FoodDTOTests: XCTestCase {
    func testStringAndMissingNutriments() throws {
        let json = """
        {
          "status": 1,
          "product": {
            "code": "12345678",
            "product_name": "Pulse Oats",
            "brands": "Shelf",
            "nutriments": {
              "energy-kcal_100g": "166",
              "proteins_100g": 7.9,
              "carbohydrates_100g": "14.3"
            }
          }
        }
        """.data(using: .utf8) ?? Data()
        let wrap = try JSONDecoder().decode(ProdWrapDTO.self, from: json)
        let item = wrap.product?.asFood()
        XCTAssertEqual(item?.name, "Pulse Oats")
        XCTAssertEqual(item?.kcal100 ?? 0, 166, accuracy: 0.001)
        XCTAssertEqual(item?.prot100 ?? 0, 7.9, accuracy: 0.001)
        XCTAssertEqual(item?.carb100 ?? 0, 14.3, accuracy: 0.001)
        XCTAssertNil(item?.fat100)
    }

    func testStatusZeroIsNotFoundShape() throws {
        let json = """
        {"status": 0, "product": {}}
        """.data(using: .utf8) ?? Data()
        let wrap = try JSONDecoder().decode(ProdWrapDTO.self, from: json)
        XCTAssertEqual(wrap.status, 0)
        XCTAssertNil(wrap.product?.asFood())
    }
}

final class A11yTests: XCTestCase {
    func testHighContrastSwapsMutedToken() {
        XCTAssertEqual(A11yLogic.mutedName(false), "plp_muted")
        XCTAssertEqual(A11yLogic.mutedName(true), "plp_ink")
        XCTAssertNotEqual(A11yLogic.mutedName(true), A11yLogic.mutedName(false))
    }

    func testPrefsPersist() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let mgr = PulseMgr(root: dir, cacheDir: dir.appendingPathComponent("c"))
        _ = await mgr.boot()
        await mgr.setA11y(A11yPrefs(schemaVersion: 1, hiContrast: true))
        await mgr.flush()
        let again = PulseMgr(root: dir, cacheDir: dir.appendingPathComponent("c"))
        _ = await again.boot()
        let p = await again.prefs()
        XCTAssertTrue(p.hiContrast)
    }
}

final class SlotRuleTests: XCTestCase {
    func testIntervalRemapsWhenPlanned() {
        XCTAssertEqual(SlotRule.resolve(slot: .interval, future: true), .dusk)
        XCTAssertEqual(SlotRule.resolve(slot: .interval, future: false), .interval)
        XCTAssertEqual(SlotRule.resolve(slot: .dawn, future: true), .dawn)
    }
}

final class StoreTests: XCTestCase {
    func testRoundTrip() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = dir.appendingPathComponent("cache", isDirectory: true)
        let mgr = PulseMgr(root: dir, cacheDir: cache)
        _ = await mgr.boot()
        let item = ShelfStore.all[1]
        let row = DayEntry.make(item: item, grams: 90, slot: .noon, day: DayKey(year: 2026, month: 1, day: 2), eaten: true)
        await mgr.addEntry(row)
        await mgr.setTgt(GoalTgt(kcal: 1800, prot: 90, carb: 180, fat: 50))
        await mgr.flush()
        let again = PulseMgr(root: dir, cacheDir: cache)
        _ = await again.boot()
        let rows = await again.allEntries()
        let tgt = await again.tgt()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].name, item.name)
        XCTAssertEqual(rows[0].grams, 90, accuracy: 0.0001)
        XCTAssertEqual(tgt.kcal, 1800)
        XCTAssertEqual(tgt.prot, 90)
    }
}
