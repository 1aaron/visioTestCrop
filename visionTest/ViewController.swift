//
//  ViewController.swift
//  visionTest
//
//  Created by Developer on 1/18/19.
//  Copyright © 2019 Aaron. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var faceImage: UIImageView!
  let picker = UIImagePickerController()
  var image: UIImage!
  @IBOutlet weak var photoImage: UIImageView!
  override func viewDidLoad() {
    super.viewDidLoad()

    picker.delegate = self
  }

  @IBAction func takePicture(_ sender: UIButton) {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      picker.sourceType = UIImagePickerController.SourceType.camera
      picker.cameraCaptureMode =  UIImagePickerController.CameraCaptureMode.photo
      picker.modalPresentationStyle = .custom
      present(picker,animated: true,completion: nil)
    } else {
      picker.sourceType = .photoLibrary
      present(picker, animated: true, completion: nil)
      let mAlert = UIAlertController(title: "Needed Feature", message: "No camera detected", preferredStyle: .alert)
      mAlert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
        mAlert.dismiss(animated: true, completion: nil)
      }))
      present(mAlert, animated: true, completion: nil)
    }
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    self.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
    photoImage.image = self.image//.resizeImage()
    image.face.crop { result in
      switch result {
      case .success(let faces):
        for image in faces {
          self.faceImage.image = image
        }
      case .notFound:
        print("couldn't find any face")
      case .failure(let error):
        print("error \(error.localizedDescription)")
      }
    }
    dismiss(animated:true, completion: nil)
    //draw and get just face
    //processImage()
  }

  func processImage() {
    var orientation: UInt32 = 0

    // detect image orientation, we need it to be accurate for the face detection to work
    switch self.image.imageOrientation {
    case .up:
      orientation = 1
    case .right:
      orientation = 6
    case .down:
      orientation = 3
    case .left:
      orientation = 8
    default:
      orientation = 1
    }

    // vision
    let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
    let requestHandler = VNImageRequestHandler(cgImage: self.image.cgImage!, orientation: CGImagePropertyOrientation(rawValue: orientation)!, options: [:])
    do {
      try requestHandler.perform([faceLandmarksRequest])
    } catch {
      print(error)
    }
  }

  func handleFaceFeatures(request: VNRequest, errror: Error?) {
    guard let observations = request.results as? [VNFaceObservation] else {
      fatalError("unexpected result type!")
    }

    for face in observations {
      addFaceLandmarksToImage(face)
    }
  }

  func addFaceLandmarksToImage(_ face: VNFaceObservation) {
    /*UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
    let context = UIGraphicsGetCurrentContext()
    // draw the image
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    context?.translateBy(x: 0, y: image.size.height)
    context?.scaleBy(x: 1.0, y: -1.0) //-1*/
    // draw the face rect
    let w = face.boundingBox.size.width * image.size.width
    let h = face.boundingBox.size.height * image.size.height
    let x = face.boundingBox.origin.x * image.size.width
    let y = face.boundingBox.origin.y * image.size.height
    let faceRect = CGRect(x: x, y: y, width: w, height: h)
    /*context?.saveGState()
    context?.setStrokeColor(UIColor.red.cgColor)
    context?.setLineWidth(8.0)
    context?.addRect(faceRect)
    context?.drawPath(using: .stroke)
    context?.restoreGState()
    // get the final image
    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
    // end drawing context
    UIGraphicsEndImageContext()
    self.photoImage.image = finalImage*/
    var croppedCGImage: CGImage?
    var orientation = 0
    switch self.image.imageOrientation {
    case .up:
      orientation = image.imageOrientation.rawValue
      let landY = image.size.height - h - y
      croppedCGImage = image!.cgImage!.cropping(to: CGRect(x: x, y: landY, width: w, height: h))
    case .right:
      let portX = image.size.width - y - h
      let portY = image.size.width - x
      croppedCGImage = image!.cgImage!.cropping(to: CGRect(x: x, y: y, width: w, height: h))
      orientation = 6
    case .down:
      croppedCGImage = image!.cgImage!.cropping(to: CGRect(x: x, y: y, width: w, height: h))
      orientation = 3
    case .left:
      croppedCGImage = image!.cgImage!.cropping(to: CGRect(x: x, y: y, width: w, height: h))
      orientation = 8
    default:
      croppedCGImage = image!.cgImage!.cropping(to: CGRect(x: x, y: y, width: w, height: h))
      orientation = 1
    }

    let cropped = UIImage(cgImage: croppedCGImage!, scale: image!.scale, orientation: image.imageOrientation)//UIImage.Orientation(rawValue: orientation)!)//image.imageOrientation)
    faceImage.image = cropped
  }
}

