//
//  TrainingPlaceCalculator.swift
//  Created by Michael Simms on 5/25/23.
//

import Foundation

enum TrainingPaceType {
	case LONG_RUN_PACE
	case EASY_RUN_PACE
	case MARATHON_PACE
	case TEMPO_RUN_PACE
	case FUNCTIONAL_THRESHOLD_PACE
	case SPEED_RUN_PACE
	case SHORT_INTERVAL_RUN_PACE
};

class TrainingPlaceCalculator {

	func ConvertToSpeed(vo2max: Double) -> Double {
		return 29.54 + 5.000663 * vo2max - 0.007546 * vo2max * vo2max
	}

	// Give the athlete's VO2Max, returns the suggested long run, easy run, tempo run, and speed run paces.
	func CalcFromVO2Max(vo2max: Double) -> Dictionary<TrainingPaceType, Double> {
		// Percentage of VO2 Max; from the USATF Coaches Education Program
		// 800 meters 120-136%
		// 1500 meters 110-112%
		// 3000 meter 100-102%
		// 5000 meters 97-100%
		// 10000 meters 88-92%
		// Half Marathon 85-88%%
		// Marathon 82-85%
		// Long Run Pace 60%
		// Easy Pace 70%
		// Tempo Pace 88%

		var longRunPace: Double = vo2max * 0.6
		var easyPace: Double = vo2max * 0.7
		var marathonPace: Double = vo2max * 0.82
		var tempoPace: Double = vo2max * 0.88
		var functionalThresholdPace: Double = vo2max * 0.90
		var speedPace: Double = vo2max * 1.1
		var shortIntervalPace: Double = vo2max * 1.15
	
		longRunPace = self.ConvertToSpeed(vo2max: longRunPace)
		easyPace = self.ConvertToSpeed(vo2max: easyPace)
		marathonPace = self.ConvertToSpeed(vo2max: marathonPace)
		tempoPace = self.ConvertToSpeed(vo2max: tempoPace)
		functionalThresholdPace = self.ConvertToSpeed(vo2max: functionalThresholdPace)
		speedPace = self.ConvertToSpeed(vo2max: speedPace)
		shortIntervalPace = self.ConvertToSpeed(vo2max: shortIntervalPace)
	
		var paces: Dictionary<TrainingPaceType, Double> = [:]
		paces[TrainingPaceType.LONG_RUN_PACE] = longRunPace
		paces[TrainingPaceType.EASY_RUN_PACE] = easyPace
		paces[TrainingPaceType.MARATHON_PACE] = marathonPace
		paces[TrainingPaceType.TEMPO_RUN_PACE] = tempoPace
		paces[TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE] = functionalThresholdPace
		paces[TrainingPaceType.SPEED_RUN_PACE] = speedPace
		paces[TrainingPaceType.SHORT_INTERVAL_RUN_PACE] = shortIntervalPace
		return paces
	}

	func CalcFromRaceDistanceInMeters(restingHr: Double, maxHr: Double, raceDurationSecs: Double, raceDistanceMeters: Double) -> Dictionary<TrainingPaceType, Double> {
		let v02MaxCalc: VO2MaxCalculator = VO2MaxCalculator()
		let vo2max = v02MaxCalc.EstimateVO2MaxFromRaceDistanceInMeters(raceDistanceMeters: raceDistanceMeters, raceTimeSecs: raceDurationSecs)
		return self.CalcFromVO2Max(vo2max: vo2max)
	}

	func CalcFromHR(restingHr: Double, maxHr: Double) -> Dictionary<TrainingPaceType, Double> {
		let v02MaxCalc: VO2MaxCalculator = VO2MaxCalculator()
		let vo2max = v02MaxCalc.EstimateVO2MaxFromHeartRate(maxHR: maxHr, restingHR: restingHr)
		return self.CalcFromVO2Max(vo2max: vo2max)
	}
}
