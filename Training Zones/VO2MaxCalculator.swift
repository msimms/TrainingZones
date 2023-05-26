//
//  VO2MaxCalculator.swift
//  Created by Michael Simms on 5/25/23.
//

import Foundation

class VO2MaxCalculator {
	func EstimateVO2MaxFromHeartRate(maxHR: Double, restingHR: Double) -> Double {
		return 15.3 * (maxHR / restingHR)
	}

	/// @brief "Daniels and Gilbert VO2 Max formula
	func EstimateVO2MaxFromRaceDistanceInMeters(raceDistanceMeters: Double, raceTimeSecs: Double) -> Double {
		let t = raceTimeSecs / 60
		let v = raceDistanceMeters / t
		return (-4.60 + 0.182258 * v + 0.000104 * pow(v, 2.0)) / (0.8 + 0.1894393 * pow(exp(1), -0.012778 * t) + 0.2989558 * pow(exp(1), -0.1932605 * t))
	}

	func EstimateVO2MaxFromRaceDistanceInMetersAndHeartRate(raceDistanceMeters: Double, raceTimeMinutes: Double, loadHr: Double, restingHr: Double, maxHr: Double) -> Double {
		return (raceDistanceMeters / raceTimeMinutes * 0.2) / ((loadHr - restingHr) / (maxHr - restingHr)) + 3.5
	}
}
