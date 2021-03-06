// Merging two depht images from two Kinects into one PGraphics  //<>//
// Note that this sketch mirrors the Kinect images. 
// This sketch also features a small hack for removing strange black bars in the left side of the depth images

// Based on:
// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import org.openkinect.freenect.*;
import org.openkinect.processing.*;


ArrayList<Kinect> multiKinect;

boolean ir = false;
boolean colorDepth = true;

int numDevices = 0;

//index to change the current device changes
int deviceIndex = 0;

float deg = 0;

PGraphics pg;

//DepthThreshold
// Depth image
PImage depthImg;
// Which pixels do we care about?
int minDepth =  60;
int maxDepth = 860;


void setup() {
  size(1280, 960);
    pg = createGraphics(640, 240); //Note that we create PGraphics that work with only half the resolution of the Kinect

  //get the actual number of devices before creating them
  numDevices = Kinect.countDevices();
  println("number of Kinect v1 devices  "+numDevices);

  //creat the arraylist
  multiKinect = new ArrayList<Kinect>();

  //iterate though all the devices and activate them
  for (int i  = 0; i < numDevices; i++) {
    Kinect tmpKinect = new Kinect(this);
    tmpKinect.enableMirror(true);
    tmpKinect.activateDevice(i);
    tmpKinect.initDepth();
    tmpKinect.initVideo();
    tmpKinect.enableColorDepth(colorDepth);

    multiKinect.add(tmpKinect);
  }
  depthImg = new PImage(640, 480);
}


void draw() {
  background(0);

  pg.beginDraw();
  for (int i  = 0; i < multiKinect.size(); i++) {
    Kinect tmpKinect = (Kinect)multiKinect.get(i);
    
    //Threshold 
    int[] rawDepth = multiKinect.get(i).getRawDepth();
    for (int j=0; j < rawDepth.length; j++) {
      if (rawDepth[j] >= minDepth && rawDepth[j] <= maxDepth) {
        depthImg.pixels[j] = color(255);
      } else {
        depthImg.pixels[j] = color(0);
      }
    }
    depthImg.updatePixels();

      image(tmpKinect.getVideoImage(), 320*i, 0, 320, 240);
      
      //Small hack for removing strange black bars in the left side of the depth images
      //It is hard on the frameRate, so might not be necessary for other setups...
      int cropAmount = 9;
      PImage croppedDepthImage = tmpKinect.getDepthImage().get(cropAmount,0,tmpKinect.getDepthImage().width-cropAmount,tmpKinect.getDepthImage().height);
      image(croppedDepthImage, 320*i, 240, 320, 240); //Be aware that this stretches the image a bit!
      //image(tmpKinect.getDepthImage(), 320*i, 240, 320, 240); // Full image without crop
      
      PImage croppedThresholdImage = depthImg.get(cropAmount,0,depthImg.width-cropAmount, depthImg.height);
      pg.image(croppedThresholdImage, 320*i, 0, 320, 240); //Be aware that this stretches the image a bit. Stretching is hard on framerate!
      //pg.image(depthImg, 320*i, 0, 320, 240);  //Full image without crop
  }
  pg.endDraw();

  image(pg, 0, 480); //The PGraphics image is the only one that merges the two images into one (usefull for other purposes)

  fill(255);
  text("Device Count: " +numDevices + "  \n" +
    "Current Index: "+deviceIndex, 660, 50, 150, 50);

  text(
    "Press 'i' to enable/disable between video image and IR image  \n" +
    "Press 'c' to enable/disable between color depth and gray scale depth \n" +
    "UP and DOWN to tilt camera : "+deg+"  \n" +
    "Framerate: " + int(frameRate), 660, 100, 280, 250);
}

void keyPressed() {
  if (key == '-') {
    if (deviceIndex > 0 && numDevices > 0) {
      deviceIndex--;
      deg = multiKinect.get(deviceIndex).getTilt();
    }
  }

  if (key == '+') {
    if (deviceIndex < numDevices - 1) {
      deviceIndex++;
      deg = multiKinect.get(deviceIndex).getTilt();
    }
  }


  if (key == 'i') {
    ir = !ir;
    multiKinect.get(deviceIndex).enableIR(ir);
  } else if (key == 'c') {
    colorDepth = !colorDepth;
    multiKinect.get(deviceIndex).enableColorDepth(colorDepth);
  } else if (key == CODED) {
    if (keyCode == UP) {
      deg++;
    } else if (keyCode == DOWN) {
      deg--;
    }
    deg = constrain(deg, 0, 30);
    multiKinect.get(deviceIndex).setTilt(deg);
  }
}