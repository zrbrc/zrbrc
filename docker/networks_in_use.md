# HOWTO

This will show all networks in-use by active containers.

    sudo docker network inspect $(sudo docker network ls -q)|grep -E "IPv4A"

![alt text](image.png)