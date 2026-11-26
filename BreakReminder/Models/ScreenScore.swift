import Foundation

public struct ScreenScoreBreakdown: Equatable {
    public let basePoints: Int
    public let breakAdherencePoints: Int
    public let naturalBreakBonus: Int
    public let skipPenalty: Int
    public let workRestRatioPoints: Int
    public let totalScore: Int
    
    public init(
        basePoints: Int = 30,
        breakAdherencePoints: Int = 0,
        naturalBreakBonus: Int = 0,
        skipPenalty: Int = 0,
        workRestRatioPoints: Int = 0,
        totalScore: Int = 100
    ) {
        self.basePoints = basePoints
        self.breakAdherencePoints = breakAdherencePoints
        self.naturalBreakBonus = naturalBreakBonus
        self.skipPenalty = skipPenalty
        self.workRestRatioPoints = workRestRatioPoints
        self.totalScore = totalScore
    }
}

public struct ScreenScore: Equatable {
    public let value: Int
    public let rating: String
    public let ratingDescription: String
    public let breakdown: ScreenScoreBreakdown
    
    public init(value: Int, breakdown: ScreenScoreBreakdown) {
        self.value = max(0, min(100, value))
        self.breakdown = breakdown
        
        if self.value >= 85 {
            self.rating = "Optimal"
            self.ratingDescription = "Excellent screen hygiene and balanced rest intervals."
        } else if self.value >= 70 {
            self.rating = "Good"
            self.ratingDescription = "Consistent pacing with minor opportunities for additional rest."
        } else if self.value >= 50 {
            self.rating = "Moderate"
            self.ratingDescription = "Noticeable continuous screen exposure. Prioritize upcoming breaks."
        } else {
            self.rating = "Needs Attention"
            self.ratingDescription = "High continuous screen exposure without sufficient rest."
        }
    }
    
    public static func calculate(for record: DailyRecord) -> ScreenScore {
        // If no work session yet today, baseline is 100
        guard record.workTimeSeconds > 0 || record.completedWorkSessions > 0 else {
            return ScreenScore(
                value: 100,
                breakdown: ScreenScoreBreakdown(
                    basePoints: 40,
                    breakAdherencePoints: 30,
                    naturalBreakBonus: 10,
                    skipPenalty: 0,
                    workRestRatioPoints: 20,
                    totalScore: 100
                )
            )
        }
        
        let base = 35
        
        // 1. Break Adherence (up to 35 points)
        let totalBreakAttempts = record.completedBreaks + record.skippedBreaks
        let breakAdherencePts: Int
        if totalBreakAttempts > 0 {
            let ratio = Double(record.completedBreaks) / Double(totalBreakAttempts)
            breakAdherencePts = Int(ratio * 35.0)
        } else {
            breakAdherencePts = 20
        }
        
        // 2. Natural Breaks Bonus (up to 15 points)
        let naturalBonus = min(15, record.naturalBreaks * 5)
        
        // 3. Work-to-Rest Ratio (up to 20 points)
        // Healthy ergonomic benchmark: roughly 5-10 minutes of rest per 50 minutes of screen
        let restRatioPts: Int
        if record.breakTimeSeconds > 0 {
            let breakMinutes = record.breakTimeSeconds / 60.0
            let workHours = max(0.5, record.workTimeSeconds / 3600.0)
            let restPerHour = breakMinutes / workHours
            if restPerHour >= 10.0 {
                restRatioPts = 20
            } else if restPerHour >= 5.0 {
                restRatioPts = 14
            } else {
                restRatioPts = 7
            }
        } else {
            restRatioPts = 0
        }
        
        // 4. Skip Penalty (-6 points per skip)
        let skipPen = record.skippedBreaks * 6
        
        let calculated = base + breakAdherencePts + naturalBonus + restRatioPts - skipPen
        let finalScore = max(10, min(100, calculated))
        
        let breakdown = ScreenScoreBreakdown(
            basePoints: base,
            breakAdherencePoints: breakAdherencePts,
            naturalBreakBonus: naturalBonus,
            skipPenalty: skipPen,
            workRestRatioPoints: restRatioPts,
            totalScore: finalScore
        )
        
        return ScreenScore(value: finalScore, breakdown: breakdown)
    }
}
