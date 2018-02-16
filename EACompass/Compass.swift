//
//  Compass.swift
//  EACompass
//
//  Created by Ehud Adler on 2/12/18.
//  Copyright © 2018 Ehud Adler. All rights reserved.
//

import UIKit
import CoreLocation // Location + Heading
import AudioToolbox // For vibration

class Compass: UIView, CLLocationManagerDelegate
{
  
  fileprivate var _lastLocation   : CLLocation? // Last location
  fileprivate var _desiredHeading : CGFloat = 0 // The desired heading private to the class. [Default: 0 (north)]
  
  var desiredHeading: CGFloat
  {                 // The desired heading inputted by the superview [GET, SET]
    set{ _desiredHeading = newValue }
    get{ return _desiredHeading     }
  }
  
  fileprivate let directionLabel  = UILabel()   // Label placed in the middle of the compass denoting current direction
  
  let locationManager: CLLocationManager = {
    $0.requestWhenInUseAuthorization()
    $0.startUpdatingLocation() // now we request to monitor the device location!
    $0.startUpdatingHeading()
    return $0
  }(CLLocationManager())
  
  /// This layer is beneath the foreground layer and will move as the phone moves
  ///
  /// It's a shape layer shaped by a bezlier path.
  /// - The dashes are [30, 90, 90, 90] meaning 30 solid, 90 blank, 90 solid...etc
  /// - Round capped
  ///
  /// This view will line up perfectly with the foreground view in one instance, making a perfect circle
  fileprivate let movingLayer: CAShapeLayer = {
    $0.fillColor       = UIColor.clear.cgColor
    $0.strokeColor     = UIColor.white.cgColor
    $0.lineWidth       = 5.0
    $0.lineDashPattern = [30, 90, 90, 90]
    $0.lineCap         = kCALineCapRound
    return $0
  }(CAShapeLayer())
  
  /// This layer is above the moving layer and will stay stationary as the phone moves
  ///
  /// It's a shape layer shaped by a bezlier path.
  /// - The dashes are [90, 90, 90, 30] meaning 90 solid, 90 blank, 90 solid...etc
  /// - Round capped
  ///
  /// This view will line up perfectly with the foreground view in one instance, making a perfect circle
  fileprivate let foregroundLayer: CAShapeLayer = {
    $0.fillColor       = UIColor.clear.cgColor
    $0.strokeColor     = UIColor.white.cgColor
    $0.lineWidth       = 5.0
    $0.lineDashPattern = [90, 90, 90, 30]
    $0.lineCap         = kCALineCapRound
    return $0
  }(CAShapeLayer())
  
  /// This layer is a small red line placed a few pixels above the circle
  /// This layer will move as the phone moves.
  /// This layer is constantly pointing toward the desiredHeading and moves counter to the moving layer
  ///
  /// It's a shape layer shaped by a bezlier path.
  /// - 5 pixels long
  /// - Round capped
  ///
  /// This view will point at toward the top of the phone when the phone is facing the desiredHeading
  fileprivate let arrowLayer = CAShapeLayer()
  
  /************ INIT *****************/
  override init(frame: CGRect)
  {
    super.init(frame: frame)
    setUp()
  }
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    setUp()
  }
  
  /************ SETUP *****************/
  fileprivate func setUp()
  {
    locationManager.delegate = self
    self.layer.cornerRadius  = self.frame.height/2
    self.backgroundColor     = UIColor.clear
    createDashedView()
    createDirectionLabel()
  }
}

extension Compass {
  
  /*********** Private ******************/
  fileprivate func createDirectionLabel()
  {
    directionLabel.font      = UIFont(name: "AvenirNext-UltraLight", size: 40)
    directionLabel.text      = "Red points east"
    directionLabel.center    = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    directionLabel.textColor = UIColor.white
    self.addSubview(directionLabel)
  }
  fileprivate func createDashedView()
  {
    
    /******* Foreground and moving layer setup *****************/
    
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 0,y: 0),
                                  radius: self.frame.width/3,
                                  startAngle: CGFloat(0),
                                  endAngle: CGFloat.pi * 2,
                                  clockwise: true)
    
    
    movingLayer.path            = circlePath.cgPath
    movingLayer.position        = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    foregroundLayer.path        = circlePath.cgPath
    foregroundLayer.position    = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    
    self.layer.addSublayer(movingLayer)
    self.layer.addSublayer(foregroundLayer)
    
    
    /******* Directional arrow layer *****************/
    let linePath = UIBezierPath()
    linePath.move   (to: CGPoint(x: self.bounds.midX, y: self.bounds.midY-self.frame.width/3 - 15))
    linePath.addLine(to: CGPoint(x: self.bounds.midX, y: self.bounds.midY-self.frame.width/3 - 20))
    
    arrowLayer.path         = linePath.cgPath
    arrowLayer.frame        = self.bounds
    arrowLayer.strokeColor  = UIColor.red.cgColor
    arrowLayer.lineCap      = kCALineCapRound
    arrowLayer.lineWidth    = 5.0
    
    self.layer.addSublayer(arrowLayer)
  }
}

extension Compass
{
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
  {
    guard let currentLocation = locations.last else { return }
    _lastLocation = currentLocation // store this location somewhere
  }
  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { return true }
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
  {
    var angle         = newHeading.trueHeading
    let rotation      = CGAffineTransform(rotationAngle: CGFloat(angle.toRadians))
    let arrowRotation = CGAffineTransform(rotationAngle: _desiredHeading.toRadians
                                                         - CGFloat(angle.toRadians)
                                                         - CGFloat(15.0.toRadians))
    
    foregroundLayer.setAffineTransform(CGAffineTransform(rotationAngle:_desiredHeading.toRadians))
    movingLayer.setAffineTransform(rotation)
    arrowLayer.setAffineTransform(arrowRotation)
    
    // Account for offset
    angle = angle + 15.0
    
    // Vibrate / Haptic feedback
    if CGFloat(angle).rounded() ==  _desiredHeading
    {
      if let iPhone_number = Int((UIDevice.current.modelName.getNumber))
      {
        if iPhone_number < 7
        {
          AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        else
        {
          let generator = UIImpactFeedbackGenerator(style: .medium)
          generator.prepare()
          generator.impactOccurred()
        }
      }else{ AudioServicesPlayAlertSound(kSystemSoundID_Vibrate) }
    }
    
    var lowerBound = _desiredHeading - 30
    if _desiredHeading < 30 {
      lowerBound = 360 - (30 - _desiredHeading) // Get proper lower bound ( avoid < 0 )
      if CGFloat(angle) > lowerBound && angle < 360 || CGFloat(angle) > 0 && CGFloat(angle) < CGFloat(Int((_desiredHeading + 30)) % 360) { bingo(angle: CGFloat(angle)) }
      else { resetCompassTraits() }
    }
    if CGFloat(angle) > lowerBound && CGFloat(angle) < CGFloat(Int((_desiredHeading + 30)) % 360) { bingo(angle: CGFloat(angle)) }
    else
    { resetCompassTraits() }
    
    if      angle > 330 && angle < 360 || angle > 0 && angle < 30   { directionLabel.text = "N"  }
    else if angle > 150 && angle < 210 { directionLabel.text = "S"  }
    else if angle > 60  && angle < 120 { directionLabel.text = "E"  }
    else if angle > 240 && angle < 300 { directionLabel.text = "W"  }
    else if angle > 30  && angle < 60  { directionLabel.text = "NE" }
    else if angle > 300 && angle < 330 { directionLabel.text = "NW" }
    else if angle > 120 && angle < 150 { directionLabel.text = "SE" }
    else if angle > 210 && angle < 240 { directionLabel.text = "SW" }
    else {}
    
    directionLabel.sizeToFit()
    directionLabel.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
  }
  fileprivate func resetCompassTraits()
  {
    movingLayer.strokeColor     = UIColor.white.cgColor
    foregroundLayer.strokeColor = UIColor.white.cgColor
    arrowLayer.strokeColor      = UIColor.red.cgColor
    directionLabel.textColor    = UIColor.white
  }
  
  fileprivate func bingo(angle: CGFloat)
  {
    
    let den = _desiredHeading != 0 ? _desiredHeading : 1
    let ratio: CGFloat          = 1 - abs(angle - den)/den
    directionLabel.textColor    = UIColor.green.withAlphaComponent(ratio)
    movingLayer.strokeColor     = UIColor.green.withAlphaComponent(ratio).cgColor
    foregroundLayer.strokeColor = UIColor.green.withAlphaComponent(ratio).cgColor
    arrowLayer.strokeColor      = UIColor.green.withAlphaComponent(ratio).cgColor
  }
}

public extension CLLocation
{
  func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat
  {
    
    let lat1 = self.coordinate.latitude.toRadians
    let lon1 = self.coordinate.longitude.toRadians
    
    let lat2 = destinationLocation.coordinate.latitude.toRadians
    let lon2 = destinationLocation.coordinate.longitude.toRadians
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    
    return CGFloat(radiansBearing)
  }
  
  func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat
  {return bearingToLocationRadian(destinationLocation).toDegrees }
}

extension CGFloat
{
  var toRadians: CGFloat { return self * .pi / 180 }
  var toDegrees: CGFloat { return self * 180 / .pi }
}
extension Double
{
  var toRadians: Double { return self * .pi / 180 }
  var toDegrees: Double { return self * 180 / .pi }
}

extension String {
  var getNumber: String {
    let pattern = UnicodeScalar("0")..."9"
    return String(unicodeScalars
      .flatMap { pattern ~= $0 ? Character($0) : nil })
  }
}

public extension UIDevice
{
  
  var modelName: String
  {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    switch identifier
    {
    case "iPod5,1":                                 return "iPod Touch 5"
    case "iPod7,1":                                 return "iPod Touch 6"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
    case "iPhone4,1":                               return "iPhone 4s"
    case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
    case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
    case "iPhone7,2":                               return "iPhone 6"
    case "iPhone7,1":                               return "iPhone 6 Plus"
    case "iPhone8,1":                               return "iPhone 6s"
    case "iPhone8,2":                               return "iPhone 6s Plus"
    case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
    case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
    case "iPhone8,4":                               return "iPhone SE"
    case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
    case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
    case "iPhone10,3", "iPhone10,6":                return "iPhone X"
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
    case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
    case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
    case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
    case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
    case "iPad6,11", "iPad6,12":                    return "iPad 5"
    case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
    case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
    case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
    case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
    case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
    case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
    case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
    case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
    case "AppleTV5,3":                              return "Apple TV"
    case "AppleTV6,2":                              return "Apple TV 4K"
    case "AudioAccessory1,1":                       return "HomePod"
    case "i386", "x86_64":                          return "Simulator"
    default:                                        return identifier
    }
  }
}
