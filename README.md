# The official repository for the *Ventus W830 Weather Station* Quick App for Fibaro Home Center 3

The Ventus W830 (and Alecto WS5500) weather stations can be configured to send weather data to a local server. To add the weather station to the Home Center 3 you can use a Raspberry Pi (or computer) to translate the payload to the FIBARO API format. With this method you can integrate the Ventus W830 or Alecto WS5500 weather station into the Home Center 3 while using your local network instead of a cloud service like [Weather Underground](https://www.wunderground.com) or [Ecowitt Weather](https://www.ecowitt.net).

## Prerequisites

- WS View app on [Google Play](https://play.google.com/store/apps/details?id=com.ost.wsview&hl=nl&gl=US) or the [iOS App Store](https://apps.apple.com/nl/app/ws-view/id1362944193),
- A Raspberry Pi or other computer with [Node-RED](https://nodered.org) installed,
- My [Ventus W830 Quick App](https://marketplace.fibaro.com/items/ventus-w830-weather-station).

## Weather station setup

Read in the manual how you link the weather station to your Wi-Fi and **install** the WS View app from [Google Play](https://play.google.com/store/apps/details?id=com.ost.wsview&hl=nl&gl=US) or the [iOS App Store](https://apps.apple.com/nl/app/ws-view/id1362944193) on your phone.

Configure the weather station to use a local server as follow:

1. **Start** the **WS View** app on your phone,
2. Tab the **menu button** and tab on **Device List**,
3. **Wait** a few seconds and your weather station shows up, tab it,
4. Tab the **next** button (upper right) a few times until you see the **Customized** screen,
5. Tab **Enable** and **Ecowitt** as **Protocol Type**,
6. Fill in the **IP address** of your Raspberry Pi (or computer),
7. Use the `/weatherstation` path when using my Node-RED flow example,
8. Fill in the **Port**, default is `1880` for Node-RED,
9. Leave the **Update Interval** at **60 seconds**,
10. Tab **Save**.

## Quick App installation

1. **Start** your favorite browser and open your Home Center 3 dashboard by typing the correct URL for your HC3,
2. Go to **Settings** and **Devices**,
3. **Click** the blue **+** icon to add a new device,
4. In the **Add Device** dialog click on **Other Device**,
5. Choose **Upload File** and upload the `.fqa` file downloaded from the FIBARO Marketplace.
6. Additionally you can change the icon of the Quick App with the attached icon.

The Quick App contains a Lua function to retrieve the weather data via the Home Center 3 API. The Node-RED flow Therefore, no additional configuration is required.

## Node-RED flow

In Node-RED you can import the following flow:

```json
[{"id":"4bd03a27.686964","type":"http in","z":"5df41914ccf9555f","name":"WS830 incoming data","url":"/weatherstation","method":"post","upload":false,"swaggerDoc":"","x":140,"y":220,"wires":[["c81fb2783c57da97"]]},{"id":"c81fb2783c57da97","type":"delay","z":"5df41914ccf9555f","name":"","pauseType":"rate","timeout":"5","timeoutUnits":"minutes","rate":"1","nbRateUnits":"5","rateUnits":"minute","randomFirst":"1","randomLast":"5","randomUnits":"seconds","drop":true,"allowrate":false,"outputs":1,"x":360,"y":220,"wires":[["44d0fc53f3f75405"]]},{"id":"44d0fc53f3f75405","type":"function","z":"5df41914ccf9555f","name":"HC3 payload","func":"weatherdata = msg.payload;\n\nmsg = {\n  headers: { 'content-type':'application/json' },\n  payload: { 'args': [weatherdata] }\n};\n\nreturn msg;","outputs":1,"noerr":0,"initialize":"","finalize":"","libs":[],"x":550,"y":220,"wires":[["147e1206594b336b"]]},{"id":"147e1206594b336b","type":"http request","z":"5df41914ccf9555f","name":"HC3 Ventus W830 QA","method":"POST","ret":"txt","paytoqs":"ignore","url":"http://192.168.1.1/api/devices/200/action/data","tls":"","persist":false,"proxy":"","authType":"basic","senderr":false,"x":760,"y":220,"wires":[[]]}]
```

The flow contains a `http in` node to retrieve the weather data payload from the station. I limit the flow so that it only sends new values to the HC3 every 5 minutes. This is not necessary, but I want to avoid unnecessary network traffic on my home network.

The function node translates the weather data JSON to a FIBARO API call and sends it to the Home Center 3 with a `http request` node.

***Note**: you have to configure **Basic Authentication** with your Home Center 3 **username** and **password** to authenticate to the API!*

As soon as you **deploy** the Node-RED flow the Home Center 3 will retrieve the weather data when it is pushed by the Ventus W830 weather station.

## Download

You can download the *Ventus W830* Quick App and documentation from the [FIBARO Marketplace](https://docs.joepverhaeg.nl).

## Full documentation

Full documentation of the Ventus W830 Weather Station Quick App is included in the provided ZIP file or on [my blog](https://docs.joepverhaeg.nl/ventus-w830/).

## About me

More interested FIBARO integrations and scenes can be found on my '[smart home adventure](https://docs.joepverhaeg.nl)' blog.