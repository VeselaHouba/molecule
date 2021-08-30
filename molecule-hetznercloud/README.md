# molecule-hetznercloud

Shared files for molecule using hetznercloud plugin to enable simpler central maintenance
Files are pulled through script "pull_files.sh", which is pulled in drone template "dronelib/drone.star"
Template has to be loaded to drone in advance, see https://docs.drone.io/template/

Yes, it's a bit complicated, but it eases the central management a LOT!
