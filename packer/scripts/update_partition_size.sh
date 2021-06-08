#!/bin/bash

# increase partition size to maximum disk size
tee -a /etc/init.d/update_partition <<EOF
#!/bin/bash

### BEGIN INIT INFO
# Provides:             update_partition
# Required-Start:       $local_fs $remote_fs $network $syslog $named
# Required-Stop:        $local_fs $remote_fs $network $syslog $named
# Default-Start:        2 3 4 5
# Default-Stop:         
# Short-Description:    updates partition 
# Description:          size to maximum disk size
### END INIT INFO
growpart /dev/sda 1
resize2fs /dev/sda1
EOF
chmod +x /etc/init.d/update_partition
update-rc.d update_partition defaults
