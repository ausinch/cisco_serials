#!/usr/bin/expect -f
##  getver_t.sh - Use telnet to get ver from Cisco devices
##  Could be asked for login ID or just pasword

set username admin
set pass {password1 password2}
set index 0
set timeout 20
set multiPrompt "(#|>)"
set host [lindex $argv 0 ]

spawn telnet $host
expect {
"name:" {
	send "$username\r"
    exp_continue
    }
"assword:" {
#    send_user "\n--- sending [lindex $pass $index] ---\n"
    send "[lindex $pass $index]\r"
    incr index
    exp_continue
}
">" { 
#    send_user "\n--- I see a prompt ---\n"
    send -- "ter len 0\r" 
    expect ">"
    send -- "show inv\r"
    expect ">"
    send -- "show ver\r"
    expect ">"
    send -- "exit\r"
    expect eof
    exit
}
timeout {
    send_user "\n--- TIMED OUT ---\n"
    exit 1
}
}
send_user "\n--- OUT SIDE FAIL ---\n"
exit 1

