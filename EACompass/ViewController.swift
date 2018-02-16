//
//  ViewController.swift
//  EACompass
//
//  Created by Ehud Adler on 2/12/18.
//  Copyright © 2018 Ehud Adler. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate
{
  let location = CLLocationManager()

  var comp = Compass()
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.black
    comp = Compass(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width))
    comp.center = self.view.center
    self.view.addSubview(comp)

  
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

