#!/usr/bin/python
#
# Agent for Check_MK to access Oracle ZFS Storage Appliance vi REST API
#
# S E T U P
#   ln -s /omd/agent_ozfssa_v1.2.py /omd/versions/default/share/check_mk/agents/special/agent_ozfssa
#   chmod +x /omd/agent_ozfssa_v1.2.py
#   su - monps[01-99]
#   vi ~/.profile
#   export PYTHONHTTPSVERIFY=0
#   omd restart
#
# U S A G E
#   su -monps[00-99]
#   ~/share/check_mk/agents/special/agent_ozfssa <zfs host> <zfs user> <zfs password>
#
# R E F
#   - https://docs.oracle.com/cd/E71909_01/html/E71922/index.html
#
# Copyright (c) 2020-03-05 Antonio Pos-de-Mina


import os, sys, getopt, json, httplib, ssl


# ZFS Appliance host name : zfs-storage.example.com
zfs_host = sys.argv[1]
# ZFS Read Only User
zfs_user = sys.argv[2]
# ZFS User Password
zfs_password = sys.argv[3]


# ---------------------------
# Agent Header

print ("""<<<check_mk>>>
Version: 1.0
AgentOS: Oracle ZFS Storage Appliance
<<<df>>>""")


# -----------------
# Azure Login

conn = httplib.HTTPSConnection(zfs_host, 215)
headers = {
    'X-Auth-User': zfs_user,
    'X-Auth-Key': zfs_password
}
conn.request("POST", "/api/access/v1", '', headers)
response = conn.getresponse()
response.read()
if response.status < 300:
    headers = {
        'X-Auth-Session': response.getheader('X-Auth-Session'),
        'Content-Type': 'application/json; charset=utf-8'
    }
    conn.request("GET", "/api/storage/v1/projects", '', headers)
    response = conn.getresponse()
    zfs_json = json.loads(response.read())
    for href in zfs_json['projects']:
        conn.request ("GET", href['href'] + "/filesystems", '', headers)
        response = conn.getresponse()
        zfs_fs = json.loads(response.read())
        for fs in zfs_fs['filesystems']:
            space_data      = fs['space_data'] / 1024
            space_available = fs['space_available'] / 1024
            space_total     = space_data + space_available
            percentage      = (space_data * 100) / (space_total)
            print "- - %d %d %d %d%% /%s/%s/%s" % (space_total, space_data, space_available, percentage, fs['pool'], fs['project'], fs['name'])

else:
    print('Not Found.')

# Close connection to HTTP server
try:
    conn.close()
except:
    print "Error close connection"
