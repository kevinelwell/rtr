tags=$(/opt/CrowdStrike/falconctl -g --tags | sed 's/^Sensor grouping tags are not set.//; s/^tags=//; s/.$//')
echo "{\"SensorTag\": \"${tags}\"}"