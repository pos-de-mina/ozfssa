# ozfssa
Oracle ZFS Storage Appliance - Monitoring with Check_MK/Nagios via REST API

## R E F
  - https://docs.oracle.com/cd/E71909_01/html/E71922/index.html

### S E T U P
```bash
ln -s /omd/agent_ozfssa_v1.2.py /omd/versions/default/share/check_mk/agents/special/agent_ozfssa
chmod +x /omd/agent_ozfssa_v1.2.py
su - monps[01-99]
vi ~/.profile
export PYTHONHTTPSVERIFY=0
omd restart
```

### U S A G E
```
su - monps[00-99]
~/share/check_mk/agents/special/agent_ozfssa <zfs host> <zfs user> <zfs password>
```
