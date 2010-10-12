/*
  Jobbox client

 Circuit:
 * Rotary Switches connected to digital pins 1-32
 * Ethernet shield attached to pins 10, 11, 12, 13
 
 created 15 March 2010
 modified 23 July 2010
 by Tom Igoe
 http://www.tigoe.net/pcomp/code/category/arduinowiring/873

 further modified 08 Sept 2010
 by Rattle
 http://rattlecentral.com

 This code is in the public domain.
 
 */

//#include <PString.h>
#include <SPI.h>
#include <Ethernet.h>

// network connection details
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xFE };
byte ip[] = { 192, 168, 2, 11 };			// ip of jobbox
byte gateway[] = { 192, 168, 2, 1 };			// gateway router ip
byte subnet[] = { 255, 255, 255, 0 };
byte server[] = { 89, 16, 191, 136 };		        // jobbox server ip

// define update host and path to post to
char host[] = "jobbox.rattlecentral.com";
char path[] = "/api";
char token[] = "YOURTOKEN";

// define boxes and their respective pins
int box0[] = {2,3,4,5,6,7,8,9};
int box1[] = {22,23,24,25,26,27,28,29};
int box2[] = {30,31,32,33,34,35,36,37};
int box3[] = {38,39,40,41,42,43,44,45};

// initialize the library instance:
//Client client(server, 3000);
Client client(server, 80);

// define the last button pressed for each box
int lbs[] = {0,0,0,0};

boolean connectedLastTime = false;    // state of the connection last time through the main loop

void setup() {
  
  Ethernet.begin(mac, ip, gateway, subnet);
  Serial.begin(9600);

  //delay(1000);
  Serial.println("connecting...");
  if (client.connect()) {
    Serial.println("connected");
  }  
  
  // make the pushbutton's pin an input:
  initializeBoxPins(box0, sizeof(box0)/sizeof(int));
  initializeBoxPins(box1, sizeof(box1)/sizeof(int));
  initializeBoxPins(box2, sizeof(box2)/sizeof(int));
  initializeBoxPins(box3, sizeof(box3)/sizeof(int));

}

void loop() {
  // if there's incoming data from the net connection.
  // send it out the serial port.  This is for debugging
  // purposes only:
  
  if (client.available()) {
    char c = client.read();
    Serial.print(c);
  }

  // if there's no net connection, but there was one last time
  // through the loop, then stop the client:
  if (!client.connected() && connectedLastTime) {
    Serial.println("disconnecting.");
    client.stop();
  }

  // check box 0 for any change
  int r0 = readBox(0, lbs[0], box0, sizeof(box0)/sizeof(int));
  if (r0 != 0) lbs[0] = r0; 
  
  int r1 = readBox(1, lbs[1], box1, sizeof(box1)/sizeof(int));
  if (r1 != 0) lbs[1] = r1;   

  int r2 = readBox(2, lbs[2], box2, sizeof(box2)/sizeof(int));
  if (r2 != 0) lbs[2] = r2; 

  int r3 = readBox(3, lbs[3], box3, sizeof(box3)/sizeof(int));
  if (r3 != 0) lbs[3] = r3;

  // store the state of the connection for next time through
  // the loop:
  connectedLastTime = client.connected();
}

// set a boxes pins to INPUT mode
void initializeBoxPins(int b[],unsigned int b_length) {
 for (int i = 0; i < b_length; i = i + 1) {
  pinMode(b[i], INPUT);
 }
}

// check to see if a boxes pins have changed
int readBox(int id, int lbs, int b[], unsigned int b_length) {
  for (int c = 0; c < b_length; c++) {
    // read the pushbutton input pin:
    int buttonState = digitalRead(b[c]);
    // make a connection only when the button goes from LOW to HIGH:
    if ((b[c] != lbs) && (buttonState == HIGH)) {
      // if you're not connected, then connect:
      //if(!client.connected()) {
        sendData(id, c);
      //}
      return b[c];
    }
  }
  return 0;
}

// this method makes a HTTP connection to the server:
void sendData(int box, int position) {
  
  Serial.println(box);
  Serial.println(position);
  Serial.println("");

  // if there's a successful connection:
  if (client.connected() || client.connect()) {
    
    Serial.println("connecting...");

    //char buffer[140];
    //PString d(buffer,sizeof(buffer));
    //d = "box=" << box << "&code=" << position;
   
    // send the HTTP POST request:
    client.print("POST http://");
    client.print(host);
    client.print(path);
    client.println(" HTTP/1.1");
    
    client.print("Host: ");
    client.println(host);

    // fill in your auth details here. It needs to be 
    // formatted like this:  username:password
    // then it needs to be  base64_encoded.  
    // you can do that online at many sites, including this one:
    // http://www.tools4noobs.com/online_php_functions/base64_encode/
    // once encoded, it'll look like a random string of characters  
  //  client.print("Authorization: Basic XXXXXXXXXXXXXXXXXXXXXXXX\n");
  //  client.print("Content-type: application/x-www-form-urlencoded\n");
    // content length of the status message that follows below:
    //client.print(strlen(data));
    //client.println("Connection: Close\n");

    client.println("Content-length: 27");
    client.println("Content-type: application/x-www-form-urlencoded");
    client.println("Connection: Close\n");

    // here's the data:
    client.print("token=");
    client.print(token);
    client.print("&box=");
    client.print(box);
    client.print("&code=");
    client.println(position);


  } 
  else {
    // if you couldn't make a connection:
    Serial.println("connection failed");
  }
}

