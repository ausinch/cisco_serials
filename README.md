# cisco_serials
Compiles a nice report of serial numbers of your Cisco switches and routers in your network and emails you.

## ./ciscoserial.sh -h
`./ciscoserial.sh logs in to Cisco devices listed in a text file (list.txt)\
extracts serial data, formats this into a report and emails it
 
Usage:\
  -s   reSend email again after asking for addresses. No device is accessed.\
  -u   Update the devices that failed last time. \
  -l   specify other Listfile. Make a text file of the devices you want to scan. \
  -b   Brain dead (simple) version of the report.  Use with s E.g. ./ciscoserial.sh -bs \
  -e   specify Email addresses.  Note: Put multiple addreesses in double quotes (")\
  -n   add Note to report. The word "none" will display no note\
  -h   this Help info.
 
Version: 1.1 - 25 June 2016 by Chris Sullivan 

##  Requirements
The Linux machine you run this from should be able to email from CLI.

Install expec and mutt\
`sudo apt install expect mutt`

The following files in the same directory:\
`ciscoserial.sh
getver_s1.sh
getver_s.sh
getver_t.s\
list.txt`

