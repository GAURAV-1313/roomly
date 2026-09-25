// Why: every screen state maps to one of nine moods. The mood is data, so the mapping from app state to
// mood can live in pure, tested code (for example DashboardSummary).
import Foundation

nonisolated enum MascotMood: String, CaseIterable, Sendable {
    case idle
    case curious
    case concerned
    case thinking
    case pleased
    case resting
    case serious
    case success
    case error

}
