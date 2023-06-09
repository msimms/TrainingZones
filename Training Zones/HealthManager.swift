//
//  HealthManager.swift
//  Created by Michael Simms on 10/7/22.
//

import Foundation
import HealthKit
import CoreLocation

class HealthManager : ObservableObject {
	static let shared = HealthManager()

	private let healthStore = HKHealthStore()
	private var workouts: Dictionary<String, HKWorkout> = [:] // summaries of workouts stored in the health store, key is the activity ID which is generated automatically
	private var queryGroup: DispatchGroup = DispatchGroup() // tracks queries until they are completed
	private var locationQueryGroup: DispatchGroup = DispatchGroup() // tracks location/route queries until they are completed
	private var hrQuery: HKQuery? = nil // the query that reads heart rate on the watch
	@Published var restingHr: Double?
	@Published var maxHr: Double?
	@Published var vo2Max: Double?
	@Published var ageInYears: Double?
	@Published var best5KDuration: TimeInterval?

	private init() {
	}
	
	func requestAuthorization() {
		
		// Check for HealthKit availability.
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}
		
		// Request authorization for things to read and write.
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
#if TARGET_OS_WATCH
		let readTypes = Set([heartRateType, restingHeartRateType, vo2MaxType, birthdayType, biologicalSexType])
#else
		let routeType = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
		let workoutType = HKObjectType.workoutType()
		let readTypes = Set([heartRateType, restingHeartRateType, vo2MaxType, birthdayType, biologicalSexType, workoutType, routeType])
#endif
		healthStore.requestAuthorization(toShare: nil, read: readTypes) { result, error in
			do {
				try self.getAge()
			}
			catch {
				NSLog("Failed to read the age from HealthKit.")
			}
			do {
				try self.getRestingHr()
				try self.getMaxHr()
			}
			catch {
				NSLog("Failed to read heart rate information from HealthKit.")
			}
			do {
				try self.getVO2Max()
			}
			catch {
				NSLog("Failed to read the VO2Max from HealthKit.")
			}
			do {
				try self.getBestRecent5KEffort()
			}
			catch {
				NSLog("Failed to read the workout history from HealthKit.")
			}
		}
	}

	func mostRecentQuantitySampleOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// Since we are interested in retrieving the user's latest sample, we sort the samples in descending
		// order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
		let timeSortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [timeSortDescriptor], resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				let sample = results!.first as! HKQuantitySample?
				callback(sample, error)
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func recentQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		let oneYear = (365.25 * 24.0 * 60.0 * 60.0)
		let startDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - oneYear)
		let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [.strictStartDate])

		let query = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func quantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// We are not filtering the data, and so the predicate is set to nil.
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func subscribeToQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantity?, Date?, Error?) -> ()) -> HKQuery {

		let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options:HKQueryOptions.strictStartDate)
		let query = HKAnchoredObjectQuery.init(type: quantityType, predicate: datePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { query, addedObjects, deletedObjects, newAnchor, error in
			
			if addedObjects != nil {
				for sample in addedObjects! {
					if let quantitySample = sample as? HKQuantitySample {
						callback(quantitySample.quantity, quantitySample.endDate, error)
					}
				}
			}
		})
		
		query.updateHandler = { query, addedObjects, deletedObjects, newAnchor, error in
			for sample in addedObjects! {
				if let quantitySample = sample as? HKQuantitySample {
					callback(quantitySample.quantity, quantitySample.endDate, error)
				}
			}
		}
		
		// Execute asynchronously.
		self.healthStore.execute(query)

		// Background delivery.
		self.healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate, withCompletion: {(succeeded: Bool, error: Error!) in
		})

		return query
	}

	/// @brief Gets the user's age from HealthKit .
	func getAge() throws {
		let dateOfBirth = try self.healthStore.dateOfBirthComponents()
		let gregorianCalendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)!
		let tempDate = gregorianCalendar.date(from: dateOfBirth)

		if tempDate != nil {
			let SECS_PER_YEAR = 365.25 * 24.0 * 60.0 * 60.0
			self.ageInYears = (Date.now.timeIntervalSince1970 - tempDate!.timeIntervalSince1970) / SECS_PER_YEAR
		}
	}

	/// @brief Gets the user's resting heart rate from HealthKit .
	func getRestingHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		
		self.mostRecentQuantitySampleOfType(quantityType: hrType) { sample, error in
			if sample != nil {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				self.restingHr = sample!.quantity.doubleValue(for: hrUnit)
			}
		}
	}
	
	/// @brief Estimates the user's maximum heart rate from the last six months of HealthKit data.
	func getMaxHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		
		self.recentQuantitySamplesOfType(quantityType: hrType) { sample, error in
			if sample != nil {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				let hrValue = sample!.quantity.doubleValue(for: hrUnit)

				if self.maxHr == nil || hrValue > self.maxHr! {
					self.maxHr = hrValue
				}
			}
		}
	}

	/// @brief Gets the user's VO2Max from HealthKit .
	func getVO2Max() throws {
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!

		self.mostRecentQuantitySampleOfType(quantityType: vo2MaxType) { sample, error in
			if sample != nil {
				let kgmin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
				let mL = HKUnit.literUnit(with: .milli)
				let vo2MaxUnit = mL.unitDivided(by: kgmin)

				self.vo2Max = sample!.quantity.doubleValue(for: vo2MaxUnit)
			}
		}
	}

	/// @brief Gets the user's best 5K effort from the last six months of HealthKit data.
	func getBestRecent5KEffort() throws {
		let startDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 86400.0 * 7.0 * 26.0)
		let predicate = HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.running)
		let sortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: false)
		let quantityType = HKWorkoutType.workoutType()
		let sampleQuery = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, samples, error in
			
			if samples != nil {
				for sample in samples! {
					if let workout = sample as? HKWorkout {
						if workout.startDate.timeIntervalSince1970 >= startDate.timeIntervalSince1970 {
							let distance = workout.totalDistance
							
							if distance != nil {
								if (distance?.doubleValue(for: HKUnit.meter()))! >= 5000.0 {
									if self.best5KDuration == nil || workout.duration < self.best5KDuration! {
										self.best5KDuration = workout.duration
									}
								}
							}
						}
					}
				}
			}
			self.queryGroup.leave()
		})
		
		self.queryGroup.enter()
		self.healthStore.execute(sampleQuery)
	}

	func clearWorkoutsList() {
		self.workouts.removeAll()
	}
	
	func readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType) {
		let predicate = HKQuery.predicateForWorkouts(with: activityType)
		let sortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: false)
		let quantityType = HKWorkoutType.workoutType()
		let sampleQuery = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, samples, error in

			if samples != nil {
				for sample in samples! {
					if let workout = sample as? HKWorkout {
						self.workouts[UUID().uuidString] = workout
					}
				}
			}
			self.queryGroup.leave()
		})

		self.queryGroup.enter()
		self.healthStore.execute(sampleQuery)
	}
	
	func readRunningWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.running)
	}

	func readWalkingWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.walking)
	}

	func readCyclingWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.cycling)
	}

	func readAllActivitiesFromHealthStore() {
		self.clearWorkoutsList()
		self.readRunningWorkoutsFromHealthStore()
		self.readWalkingWorkoutsFromHealthStore()
		self.readCyclingWorkoutsFromHealthStore()
		self.waitForHealthKitQueries()
	}

	private func readLocationPointsFromHealthStoreForWorkoutRoute(route: HKWorkoutRoute, activityId: String) {
		let query = HKWorkoutRouteQuery.init(route: route) { _, routeData, done, error in

			if done {
				self.queryGroup.leave()
			}
		}

		self.queryGroup.enter()
		self.healthStore.execute(query)
	}

	func readLocationPointsFromHealthStoreForWorkout(workout: HKWorkout, activityId: String) {
		let predicate = HKQuery.predicateForObjects(from: workout)
		let sampleType = HKSeriesType.workoutRoute()
		let query = HKAnchoredObjectQuery.init(type: sampleType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { _, samples, _, _, error in

			if samples != nil {
				for sample in samples! {
					if let route = sample as? HKWorkoutRoute {
						self.readLocationPointsFromHealthStoreForWorkoutRoute(route: route, activityId: activityId)
					}
				}
			}

			self.queryGroup.leave()
		})

		self.queryGroup.enter()
		self.healthStore.execute(query)
		self.waitForHealthKitQueries()
	}

	func readLocationPointsFromHealthStoreForActivityId(activityId: String) {
		guard let workout = self.workouts[activityId] else {
			return
		}
		self.readLocationPointsFromHealthStoreForWorkout(workout: workout, activityId: activityId)
	}

	/// @brief Blocks until all HealthKit queries have completed.
	func waitForHealthKitQueries() {
		self.queryGroup.wait()
	}

	func unsubscribeFromHeartRateUpdates() {
		guard self.hrQuery != nil else {
			return
		}

		self.healthStore.stop(self.hrQuery!)
		self.hrQuery = nil
	}
}
