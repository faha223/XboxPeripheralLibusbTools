# Setting up Xbox Controllers for use with libusb-1.0
#### Installation guide for Xbox Controllers, Memory Cards, and Xbox Live Communicator Headsets for use with libusb passthrough in Xemu

## Device Setup
### Linux
All you need to do to get Xbox Controllers ready for libusb in Linux is to set up some udev rules to enable read/write access
```
git clone https://github.com/faha223/XboxPeripheralUdevRules.git
cd XboxPeripheralUdevRules
./install.sh
```
### Windows
Setting up Xbox Controllers for libusb-1.0 in Windows simply requires assigning a libusb-1.0 compatible driver 
for the device.

The simplest way to do this, I have found, is to use Zadig to set up the device to use either a WinUSB driver or the LibusbK driver. WinUSB is the recommended driver to use for controllers, but you'll need to use the libusbK driver for the Xbox Live Communicator headset.

The latest version of Zadig can be found here: [Zadig](https://zadig.akeo.ie/)

You can find more information about using libusb on Windows here: 
[How to use libusb on Windows](https://github.com/libusb/libusb/wiki/Windows#how-to-use-libusb-on-windows)

### macOS
As far as I know, libusb just works on macOS with no additional setup. I haven't tried it.

## Connecting a libusb passthrough device in Xemu using the Monitor
Connecting a libusb controller in xemu can be done in a few different ways. The two most common ways are:
  - Forwarding a controller by forwarding the ports of its internal hub to the ports of a virtual hub
  - Forwarding a controller by forwarding a specific device by hardware ID to a controller port

To connect a controller by forwarding the ports of its internal hub (this is how you'd want to connect an xbox controller if you intend to use its expansion slots)
- Figure out what bus and port the controller is on
  - On Linux, open a terminal and type `lsusb -t`
    - The result should look something like this:
    ```
    /:  Bus 001.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/6p, 480M
        |__ Port 001: Dev 002, If 0, Class=Vendor Specific Class, Driver=[none], 12M
        |__ Port 002: Dev 003, If 0, Class=Hub, Driver=hub/4p, 480M
            |__ Port 002: Dev 004, If 0, Class=Hub, Driver=hub/3p, 12M
                |__ Port 001: Dev 005, If 0, Class=Xbox, Driver=xpad, 12M
    ```
    - If you follow the tree you'll find that the first Xbox class device (the the controller device, which exists on port 1 of the controller's internal hub)
      - You can tell from the out put that the device is on Bus 001
      - If you follow the tree from the top to the Xbox class device, noting the Ports along the way, you'll see that the controller is on port 1.2.2.1 of the bus.
  - On Windows, you'll need to use something like USBView to determine the host bus and host port of your device

- Open the monitor by pressing the tilde [~] key
- Type `stop` to pause emulation
- Type `device_add usb-hub,port=1.3,ports=3` to add the internal hub of the controller to Player 1's controller port
- Type `device_add usb-host,hostbus=1,hostport=1.2.2.1,port.1.3.1` to forward the controller to port 1 of the virtual controller's hub
- Type `device_add usb-host,hostbus=1,hostport=1.2.2.2,port=1.3.2` to forward Expansion Slot A to port 2 of the virtual controller's internal hub (optional)
- Type `device_add usb-host,hostbus=1,hostport=1.2.2.3,port=1.3.3` to forward Expansion Slot B to port 3 of the virtual controller's internal hub (optional)
- Type `cont` to resume emulation

To connect a controller by Vendor ID and Product ID (this is easier than forwarding the controller's internal ports, but is not as robust)
- Open the monitor by pressing the tilde [~] key
- Type `stop` to pause emulation
- Type `device_add usb-host,vendor_id=XXXX,product_id=YYYY,port=1.3` to forward you device by Vendor ID and Product ID to the Player 1 port.   
  - You'll need to replace XXXX with the vendor id of your device
  - You'll need to replace YYYY with the product ID of your device
  - In Linux, you can find the vendor id and product id by typing `lsusb | grep Xbox` in the terminal.
    - You should see something like this somewhere in the resulting text
    ```
    Bus 001 Device 004: ID 045e:0288 Microsoft Corp. Xbox Controller S Hub
    Bus 001 Device 005: ID 045e:0289 Microsoft Corp. Xbox Controller S
    ```
    - In this instance the vendor ID is 045e and the Product Id is 0289, so the command you would enter in the Monitor to forward this device to Player 1's controller port is `device_add usb-host,vendor_id=045e,product_id=0289,port=1.3`.
  - In Windows you can find the Vendor Id and Product Id of a device in the Device Manager
    - Find the device in the list
    - Right click the device in the list and select "Properties" from the context menu.
    - In the Device Properties window that opens up, navigate to the Details tab
    - The Property drop-down, find "Hardware IDs"
    - There should be a line in the Value box that looks like `USB\VID_045E&PID_0289`. This is the vendor id and product id of the device.
    - In this instance the vendor ID is 045e and the Product Id is 0289, so the command you would enter in the Monitor to forward this device to Player 1's controller port is `device_add usb-host,vendor_id=045e,product_id=0289,port=1.3`.
  - In macOS I suspect you can just follow the Linux instructions, but I don't know for certain
- Type `cont` to resume emulation

## Troubleshooting
Things don't always go the way we want them to. Here's a list of solutions for some common problems

### Linux
If you have installed the udev rules and have forwarded the device to your controller port, and usb passthrough still isn't working, here are some things to try that might be the problem
- If you're using an older kernel than 4627, and you're following the instructions to forward the device by Vendor ID and Product ID, but the device is a controller with expansion slots, you need to create a virtual hub to forward the device to.
  - After executing `stop` to pause emulation, and before forwarding the controller, type `device_add usb-hub,port=1.3,ports=3` to add a virtual usb hub to Player 1's port.
  - After creating the virtual hub, you can no longer forward your device directly to the controller port. Instead, forward the device to port `1.3.1`. This is the first port on the virtual usb hub.
- You might need to enable the xpad kernel module to ensure a compatible driver is being used with your device
  - To check which driver is being used with this controller, type `lsusb -t` in the Terminal. You should see a line that looks like this:
    ```
    Port 001: Dev 005, If 0, Class=Xbox, Driver=xpad, 12M
    ```
  - If it says something other than `Driver=xpad` then you might be using an incompatible driver. 
  - One way to check that the xpad kernel module is enabled is to type `lsmod | grep xpad`. If it's working, you should see something like this in the output
  ```
  xpad                   49152  0
  ```
  - If the xpad module isn't running, you can enable it by running `sudo modprobe xpad` from the terminal.

## Additional Information

### Controller Ports
Controller ports are not linearly mapped in the Xbox's hardware. For this most part, this is hidden by Xemu. However, when users occasionally have to do things through the monitor this information is needed. This table shows which USB port is used for which player
| Player | Xemu Port Number |
|:------:|:----------------:|
| 1      | 1.3              |
| 2      | 1.4              |
| 3      | 1.1              |
| 4      | 1.2              |

### Well Known Device Vendor IDs and Product IDs
These can be used to connect controllers in Xemu by Vendor ID and Product ID.

| Device Name                | Vendor ID | Product ID |
|----------------------------|:---------:|:----------:|
| Xbox Controller            | 045e      | 0202       |
| Xbox Controller S (Japan)  | 045e      | 0285       |
| Xbox Controller S          | 045e      | 0287       |
| Xbox Controller S (USA)    | 045e      | 0289       |
| Xbox Live Communicator     | 045e      | 0283       |
| Xbox Memory Unit (8 MB)    | 045e      | 0280       |
| Steel Battalion Controller | 0a7b      | d000       |