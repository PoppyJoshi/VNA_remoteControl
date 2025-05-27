# VNA_remoteControl
Code for programming the keysight ENA5061B via MATLAB for data logging of the S11 parameters


---------------- VNA data Acquisition PJ 22/05/22025----------------------

This code is designed to connect to the keysight ENA 5061B via USB-A --> USB-B, read in the S11 parameters and calculate the impedance. We can also use this to set parameters/scales on the VNA remotely.

 First, download the 'prerequisit' and 'main' keysight IO software to use the connection expert, which will give the USB VISA address from https://www.keysight.com/us/en/lib/software-detail/computer-software/io-libraries-suite-downloads-2175637.html.

SCIP commands can be found here
https://helpfiles.keysight.com/csg/e5061b/programming/command_reference/index.htm


If the connection expert displays the device is connected but MATLAB won't connect it is likely that it has stored multiple connection attempts and gets confused... Use:
instrfind - to display the connections
instrhwinfo - to displace the info of the connected device
instrreset - to clear the connections
When you do 'instrfind' after 'instrreset', it should return an empty array
i.e.  instrfind = []

SDATA? - obtains the S-data

FDATA? - obtains the current trace data. Less reliable, less info, I don't recommend using this.
