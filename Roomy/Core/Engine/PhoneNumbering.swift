// Why: the same number is written "+33 6 12 34 56 78" abroad and "06 12 34 56 78" at home. Turning the home
// form into the international one needs the country's calling code and the prefixes dialled before it,
// which differ by region. The table is local data, not a phone-number library, and a region it does not
// know simply compares numbers digit for digit, so a gap costs a missed match, never a wrong one.
import Foundation

nonisolated struct PhoneNumbering: Sendable {
    /// The region's country calling code, or nil when the region is unknown.
    let callingCode: String?
    private let region: String

    init(region: String) {
        self.region = region.uppercased()
        callingCode = Self.callingCodes[self.region]
    }

    /// The digits after the international call prefix ("00", or "011" in North America), or nil when the
    /// number does not start with it.
    func droppingInternationalPrefix(_ digits: String) -> String? {
        let prefix = Self.internationalPrefixes[region] ?? "00"
        return digits.hasPrefix(prefix) ? String(digits.dropFirst(prefix.count)) : nil
    }

    /// The national significant number: the digits without the trunk prefix dialled only at home.
    func droppingTrunkPrefix(_ digits: String) -> String {
        if callingCode == "1" {
            return Self.dropping(trunk: "1", from: digits, whenLength: Self.trunkedElevenDigits)
        }
        switch region {
        case "RU", "KZ", "BY":
            return Self.dropping(trunk: "8", from: digits, whenLength: Self.trunkedElevenDigits)
        case "HU":
            return Self.dropping(trunk: "06", from: digits, whenLength: nil)
        case "IT", "SM", "VA":
            return digits  // the leading 0 is part of the number here, and is dialled from abroad too
        default:
            return Self.dropping(trunk: "0", from: digits, whenLength: nil)
        }
    }

    private static func dropping(trunk: String, from digits: String, whenLength length: Int?) -> String {
        guard digits.hasPrefix(trunk), length == nil || digits.count == length else { return digits }
        return String(digits.dropFirst(trunk.count))
    }

    /// North American and Russian numbers are ten digits; with their trunk prefix they are eleven.
    private static let trunkedElevenDigits = 11

    private static let internationalPrefixes: [String: String] = [
        "US": "011", "CA": "011", "PR": "011", "AU": "0011", "JP": "010",
    ]

    /// Region code followed by calling code, space separated, parsed once.
    private static let callingCodes: [String: String] = {
        let table = """
            US1 CA1 PR1 VI1 GU1 AS1 MP1 AG1 AI1 BB1 BM1 BS1 DM1 DO1 GD1 JM1 KN1 KY1 LC1 MS1 SX1 TC1 TT1 VC1 VG1 \
            RU7 KZ7 EG20 ZA27 GR30 NL31 BE32 FR33 ES34 HU36 IT39 VA39 RO40 CH41 AT43 GB44 GG44 IM44 JE44 DK45 \
            SE46 NO47 SJ47 PL48 DE49 PE51 MX52 CU53 AR54 BR55 CL56 CO57 VE58 MY60 AU61 CX61 CC61 ID62 PH63 NZ64 \
            SG65 TH66 JP81 KR82 VN84 CN86 TR90 IN91 PK92 AF93 LK94 MM95 IR98 SS211 MA212 EH212 DZ213 TN216 \
            LY218 GM220 SN221 MR222 ML223 GN224 CI225 BF226 NE227 TG228 BJ229 MU230 LR231 SL232 GH233 NG234 \
            TD235 CF236 CM237 CV238 ST239 GQ240 GA241 CG242 CD243 AO244 GW245 IO246 SC248 SD249 RW250 ET251 \
            SO252 DJ253 KE254 TZ255 UG256 BI257 MZ258 ZM260 MG261 RE262 YT262 ZW263 NA264 MW265 LS266 BW267 \
            SZ268 KM269 SH290 ER291 AW297 FO298 GL299 GI350 PT351 LU352 IE353 IS354 AL355 MT356 CY357 FI358 \
            AX358 BG359 LT370 LV371 EE372 MD373 AM374 BY375 AD376 MC377 SM378 UA380 RS381 ME382 XK383 HR385 \
            SI386 BA387 MK389 CZ420 SK421 LI423 FK500 BZ501 GT502 SV503 HN504 NI505 CR506 PA507 PM508 HT509 \
            GP590 BL590 MF590 BO591 GY592 EC593 GF594 PY595 MQ596 SR597 UY598 CW599 BQ599 TL670 NF672 BN673 \
            NR674 PG675 TO676 SB677 VU678 FJ679 PW680 WF681 CK682 NU683 WS685 KI686 NC687 TV688 PF689 TK690 \
            FM691 MH692 KP850 HK852 MO853 KH855 LA856 BD880 TW886 MV960 LB961 JO962 SY963 IQ964 KW965 SA966 \
            YE967 OM968 PS970 AE971 IL972 BH973 QA974 BT975 MN976 NP977 TJ992 TM993 AZ994 GE995 KG996 UZ998
            """
        let entries = table.split(separator: " ").map { (String($0.prefix(2)), String($0.dropFirst(2))) }
        return Dictionary(entries, uniquingKeysWith: { first, _ in first })
    }()
}
