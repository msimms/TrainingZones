# TrainingZones
An open source calculator for heart rate zones, cycling power zones, and run training paces. Uses Apple HealthKit.

## Heart Rate
Heart rate zones are calculated using the Karvonen formula, based on heart rate reserve. This calculation involves reading resting heart rate from Apple Health and estimating maximum heart rate from the last year of heart rate data.

## Cycling Power
Cycling power zones are calculated based on the functional threshold power entered by the user.

## Run Training Paces
Run training paces are computed from VO2Max, if VO2Max is available in Apple Health. Otherwise, paces will be calculated using an estimated VO2Max derived from the fastest run of 5 KM or greater in the last six months.

## Building
This app is built using Apple XCode. Every attempt is made to stay up-to-date with the latest version of XCode and the latest version of iOS. In theory, if you have cloned the source code repository and initialized the submodules, then you should be able to open the project in XCode, build, and deploy.
```
git clone https://github.com/msimms/Training\ Zones
cd Training\ Zones
git submodule update --init
```

## Version History
1.0 - Initial release

## License
This is open source software and is released under the MIT license.
