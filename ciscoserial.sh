#!/bin/bash
#  Script to interigate Cisco switches and routers, get version information and generate a report.
#  by Chris Sullivan  July 2014 v1.0
#  modified csullivan June 2016.  added IOS version. v1.1 and total expect script rewrites to encorporate IOS versions.
VERSION="1.1 - 25 June 2016"

## Function to access and get the info
#  Will try protocols telnet, sshv2 & sshv1 in that order
function access()
{
    #  Is telnet port open? then access
    if [[ $ports == *telnet* ]]; then
        echo -n "- trying telnet "
        ERROR=$((./getver_t.sh $T >> $outputfile) 2>&1)
        protocol="telnet"
        #  Return if successful
        if grep -q DESCR $outputfile ; then return 0; fi
    fi
    echo -n "- trying sshv2 "
    ERROR=$((./getver_s.sh $T >> $outputfile) 2>&1)
    protocol="sshv2"
    #  Return if successful
    if grep -q DESCR $outputfile ; then return 0; fi
    echo -n "- trying sshv1 "
    ERROR=$((./getver_s1.sh $T >> $outputfile) 2>&1)
    protocol="sshv1"
    #  Return if successful
    if grep -q DESCR $outputfile ; then return 0; fi
    protocol="FAILED"
    errorcount=$((errorcount+1))
    return 1
}
function getT()
{
    outputfile="$tmpdir$T.txt"
    echo $T  > $outputfile
    echo -n "Processing $T "
    echo "------------------" >> Error.txt
    echo "$T" >> Error.txt

    ##  Look at open ports then access the device.
    #  Check to see if device is alive
    ports=`nmap -n -A -p 22,23 $T |grep -i open`
    if [[ "X$ports" == "X" ]]; then
        protocol="FAILED - BAD ADDRESS"
        errorcount=$((errorcount+1))
        ERROR="$ERROR $protocol"
    else
        access
    fi
    echo " " >> $outputfile
    echo "Protocol: $protocol" >> $outputfile
    echo "ScanDate: $(date)" >> $outputfile
    echo "$ERROR" >> Error.txt
    echo "- $protocol"
}

#  Set up parameters
tmpdir="./tmp/"
listfile="list.txt"
defaultemail="csullivan@transre.com"
reportname="Report.html"
updateonly="Not ok"

#  Get parameters
while getopts shuf:e:n:bl:x opts; do
    case ${opts} in
        u) updateonly="ok" ;;
    s) sendonly="ok" ;;
g) genonly="ok" ;;
        b) braindead="Yes" ;;
    e) eaddress=${OPTARG} ;;
n) note=${OPTARG} ;;
        l) 
            listfile=${OPTARG} 
            tmpdir="./tmp$listfile/"
            ;;
        x) exit ;;
    h)
        echo "$0 logs in to Cisco devices listed in a text file ($listfile)"
        echo "  extracts serial data, formats this into a report and emails it"
        echo " "
        echo "Usage:"
        echo "  -s   reSend email again after asking for addresses. No device is accessed."
        echo "  -u   Update the devices that failed last time. "
        echo "  -l   specify other Listfile. Make a text file of the devices you want to scan. "
        echo "  -b   Brain dead (simple) version of the report.  Use with s E.g. $0 -bs "
        echo "  -e   specify Email addresses.  Note: Put multiple addreesses in double quotes (\")"
        echo "  -n   add Note to report. The word \"none\" will display no note"
        echo "  -h   this Help info."
        echo " "
        echo "Version: $VERSION by Chris Sullivan "
        echo " "
        exit
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
esac
done

##  Debug info
# echo "updateonly: $updateonly    sendonly: $sendonly    braindead: $braindead"
# echo "listfile: $listfile    tmpdir: $tmpdir"

#  Make sure tmp area exists
if [ ! -d "$tmpdir" ]; then
    mkdir $tmpdir
    if [ ! -d "$tmpdir" ]; then
        echo "Error: I cant create the temp directory $tmpdir"
        echo " Aborting the script.   "
        exit
    fi
fi

##  If -e not used get email address
if [ "X$eaddress" == "X" ]; then
    #  Get email address from user
    echo "Welcome to the Cisco Serial Extractor."
    echo "Version: $VERSION"
    echo  "Please enter email addresses you wish the report sent to seperated by spaces."
    echo "E.g $defaultemail (Default)"
    echo " "
    echo -n "Email Addresses: "
    read eaddress
    if [ "X$eaddress" == "X" ]; then
        eaddress=$defaultemail
    fi
    echo " ";echo " "
fi  #  end -e

##  Add note
if [ "X$note" == "X" ]; then
    echo "Do you wish to add a note to the report?"
    echo "Enter nothin for no note"
    echo " "
    read note
    if [ "X$note" == "X" ]; then
        note="none"
    fi
    echo " "
fi 

#  Do this if sendonly -s doesnt exists
if [ "$sendonly" != "ok" ]; then

    ##  updateonly logic; pass if flag not set or flag set and no FAIL in file
    if [ "$updateonly" != "ok" ]; then

        #  Clean up tmp directory
        rm $tmpdir*
        rm Error.txt

        echo " "
        echo "Here is the list I will process:"
        cat $listfile
        echo " "
        echo "Starting . . . . "

        #  Get the file list and process.
        #  Dump the command output to $tmpdir/device_name

        while read line
        do
            #  Skip remarks and blank lines in the list file
            if [[ `echo $line |cut -b 1` != "#" ]]; then
                if [[ $line != "" ]]; then
                    #  Get parameters
                    T="$(echo $line|awk '{print $1}')"
                    getT
                fi  #  skip blank line in list
            fi  #  skip remark line in list
        done < $listfile
    else
        #  Update Only
        echo "I am about to update all the FAILed status devices in $tmpdir"
        echo "I will be updating these files:"
        FILES=$(fgrep FAILED tmp/*|awk -F\: '{print $1}')
        echo "$FILES"
        for T1 in $FILES
        do
            T=$(head -n 1 "$T1")
            getT
        done
    fi  # end updateonly

    echo "Errors: $errorcount"
    #fi  #  genonly return

fi  # sendonly return

echo " "
echo -n "Building report "

#  Start processing the files and create the report in html
#  First the header

echo "<html><head><title>Cisco Serial numbers</title><style>body {font-family: helvetica, arial; font-size: 10px;}h1 {font-family: helvetica, arial; font-size: 20px;}ps {font-family: helvetica, arial; font-size: 10px;}p {font-family: helvetica, arial; font-size: 14px;}</style></head><body>" > $reportname
#  Pretty it up
echo "<style type=\"text/css\">
.tftable {font-size:12px;color:#333333;border-width: 1px;border-color: #729ea5;border-collapse: collapse;}
.tftable th {font-size:12px;background-color:#acc8cc;border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;text-align:left;}
.tftable tr {background-color:#d4e3e5;}
.tftable td {font-size:12px;border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;white-space:nowrap;}
.tftable tr:hover {background-color:#ffffff;}
</style>" >> $reportname
echo "<h1>Cisco Serial numbers</h1><br>" >> $reportname
if [ "X$note" != "Xnone" ]; then
    echo "<table class=\"tftable\" border=\"1\"><tr><td><b>Note:</b><br>$note</td></tr></table><br>" >> $reportname
fi

echo "<p>Report created $(date)</p>" >> $reportname
##  Brain dead version or full version
if [ "X$braindead" == "XYes" ]; then
    echo "<p><i>Simplified verion</i></p>" >> $reportname
    echo "<table class=\"tftable\" border=\"1\"><tr><th>Device</th><th>System Name</th><th>IOS version</th><th><th>System Serial</th><th>Model</th><th>Board Revision</th><th>Protocol</th><th>Scan Date</th></tr>" >> $reportname
else
    echo "<table class=\"tftable\" border=\"1\"><tr><th>Device</th><th>System Name</th><th>IOS version</th><th>Dev Name</th><th>Description</th><th>PID</th><th>Serial</th><th>Board Revision</th><th>Protocol</th><th>Scan Date</th></tr>" >> $reportname
fi
FILES=$tmpdir*.txt
for T in $FILES
do
    echo -n " ."
    #  Device
    echo "<tr><td>" >> $reportname
    echo "$(basename $T|sed s/\.txt//) </td><td>" >> $reportname

    #  System Name
    grep "uptime" $T |awk '{print $1}' >> $reportname
    echo "</td><td>" >> $reportname
    #  IOS version
    grep "IOS Software" $T | sed 's/Cisco IOS Software,//' >> $reportname
    echo "</td><td>" >> $reportname
    if [ "X$braindead" == "XYes" ]; then
        #  System serial
        grep "System serial" $T |awk '{print $5}'|sed 's/$/<br>/' >> $reportname
        grep "*0" $T |awk '{print $3}' >> $reportname
        echo "</td><td>" >> $reportname

        #  Model
        grep "Model number" $T |awk '{print $4}'|sed 's/$/<br>/' >> $reportname
        grep "*0" $T |awk '{print $2}' >> $reportname
        echo "</td><td>" >> $reportname
    else
        #  Inventory
        grep "NAME:" $T |awk -F\" '{print $2}'|sed 's/$/<br>/' >> $reportname
        echo "</td><td>" >> $reportname
        grep "NAME:" $T |awk -F\" '{print $4}'|sed 's/$/<br>/' >> $reportname
        echo "</td><td>" >> $reportname
        grep "PID:" $T |awk '{print $2}'|sed 's/$/<br>/' >> $reportname
        echo "</td><td>" >> $reportname
        grep "PID:" $T |awk '{print $NF}'|sed 's/$/<br>/' >> $reportname
        echo "</td><td>" >> $reportname
    fi	
    #  Board Revision
    grep "Board Revision" $T |awk '{print $6}' >> $reportname
    echo "</td><td>" >> $reportname

    #  Protocol Used
    grep "Protocol:" $T |awk '{print $2}' >> $reportname
    echo "</td><td>" >> $reportname

    #  Scan Date
    grep "ScanDate:" $T |awk '{print $4" "$3" "$7}' >> $reportname
    echo "</td></tr>" >> $reportname
done
# Close the table
echo "</table><br>" >> $reportname

#  Report Footer
if [ "X$errorcount" == "X" ]; then
    errorcount="None"
fi
echo "Error count: $errorcount  <br>" >> $reportname
echo "Using file:  $listfile  <br>" >> $reportname
#echo "Parameters:<br><pre>&#9;</pre>tmpdir: <pre>&#9;</pre>$tmpdir<br><pre>&#9;</pre>listfile<pre>&#9;</pre>$listfile<br><pre>&#9;</pre>reportname<pre>&#9;</pre>$reportname<br><pre>&#9;</pre>updateonly<pre>&#9;</pre>$updateonly<br><pre>&#9;</pre>sendonly<pre>&#9;</pre>$sendonly<br><pre>&#9;</pre>eaddress<pre>&#9;</pre>$eaddress<br><br>" >> $reportname
echo "<br>Script by Chris Sullivan </html>" >> $reportname
echo "  Done."

echo "Emailing."
mutt -e "set content_type=text/html" -s "Cisco Serials" $eaddress < Report.html
echo "All Done."

