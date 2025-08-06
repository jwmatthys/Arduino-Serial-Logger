import processing.serial.*;
import controlP5.*;
import javax.swing.JFileChooser;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;

ControlP5 cp5;
Button toggleButton;

Serial myPort;
PrintWriter output;

String[] portList;
boolean portConnected = false;
boolean loggingActive = false;
boolean folderSelected = false;

String folderPath = System.getProperty("user.home");
String fileName;
String filePath;

String[] consoleLines = new String[20]; // Live serial monitor

void setup() {
  size(800, 450);
  background(255);
  textFont(createFont("Courier", 14));
  cp5 = new ControlP5(this);

  // List serial ports
  portList = Serial.list();
  /*
  println("Available ports:");
  for (int i = 0; i < portList.length; i++) {
    println(i + ": " + portList[i]);
  }
  */

  // Dropdown for port selection
  cp5.addScrollableList("portSelector")
    .setPosition(20, 20)
    .setSize(200, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(java.util.Arrays.asList(portList))
    .setLabel("Select Serial Port");

  // Start/Stop logging button
  toggleButton = cp5.addButton("toggleLogging")
    .setPosition(20, 140)
    .setSize(200, 30)
    .setLabel("Start Logging");
  for (int i = 0; i < consoleLines.length; i++) {
    consoleLines[i] = "";
  }
}

void draw() {
  // Clear live monitor area
  fill(255);
  noStroke();
  rect(250, 20, width - 260, height - 40);
  // Clear Logging status area
  rect(20,185,150,20);
  
  fill(230);
  rect(10,10,220,200,10,10,10,10);

  fill(0);
  text("Live Serial Monitor:", 260, 40);
  for (int i = 0; i < consoleLines.length; i++) {
    text(consoleLines[i], 260, 60 + i * 16);
  }

  if (loggingActive) {
    fill(0, 150, 0);
    text("Logging: ON", 20, 200);
  } else {
    fill(180, 0, 0);
    text("Logging: OFF", 20, 200);
  }
}

void portSelector(int index) {
  if (!portConnected && index >= 0 && index < portList.length) {
    String selectedPort = portList[index];
    try {
      myPort = new Serial(this, selectedPort, 9600);
      myPort.clear();
      myPort.bufferUntil('\n');
      portConnected = true;
      println("Connected to: " + selectedPort);
      selectFolder("Select folder to save CSV:", "folderSelectedCallback");
    }
    catch (Exception e) {
      println("Failed to open port: " + selectedPort);
      e.printStackTrace();
    }
  }
}

void toggleLogging() {
  if (!portConnected || !folderSelected) {
    println("Cannot start logging: Port or folder not selected.");
    return;
  }

  loggingActive = !loggingActive;

  if (loggingActive) {
    fileName = "arduino_log_" + getTimestamp() + ".csv";
    filePath = folderPath + File.separator + fileName;
    output = createWriter(filePath);
    println("Started logging to: " + filePath);
    toggleButton.setLabel("Stop Logging");
  } else {
    if (output != null) {
      output.flush();
      output.close();
    }
    println("Stopped logging.");
    toggleButton.setLabel("Start Logging");
  }
}

void folderSelectedCallback(File selection) {
  if (selection != null) {
    folderPath = selection.getAbsolutePath();
    println("Selected folder: " + folderPath);
  } else {
    println("No folder selected. Using home directory.");
  }
  folderSelected = true;
}

void serialEvent(Serial p) {
  String inData = trim(p.readStringUntil('\n'));
  if (inData != null && !inData.isEmpty()) {
    updateConsole(inData);
    if (loggingActive && output != null) {
      output.println(inData);
      output.flush();
    }
  }
}

void updateConsole(String line) {
  for (int i = 0; i < consoleLines.length - 1; i++) {
    consoleLines[i] = consoleLines[i + 1];
  }
  consoleLines[consoleLines.length - 1] = line;
}

String getTimestamp() {
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
  return sdf.format(new Date());
}

void exit() {
  if (output != null) {
    output.flush();
    output.close();
  }
  super.exit();
}
