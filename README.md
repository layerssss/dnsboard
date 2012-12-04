dnsboard
========

a static dns records manager for routerOS , make by nodejs.

compile
========

    npm install
    sudo npm install coffee-script -g
    make

config
========
configuration is done vie ENVs, eg.:

    export ROS_ADDR 192.168.0.1
    export ROS_USER admin
    export ROS_PASS yourpassword
    export PORT 80


launch
========

    node .

    