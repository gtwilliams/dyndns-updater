# dyndns-updater
Keep DNS Record Updated For Home Machine

This is a simple daemon that wakes up every two hours to check if our
IP address has changed since the last time we checked.  If a change is
detected update.dyn.com is contacted to update our DNS A record.
