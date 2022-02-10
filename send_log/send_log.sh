#!/bin/bash
send() {
  FORMAT='{"Json":"%s","Sent":%s,"Deleted":%s}\n'
  mapfile -t CONTENT < $4
  EVENTS=$(for l in ${CONTENT[@]}; do printf '{"timestamp":'"$(date +%s%3N)"',"attributes":%s}' "$l"; done)
  JSON=$(echo ${4##*/})
  BODY=$(printf '[{"tags":{%s,"json":"%s"},"events":[%s]}]' "$3" "$JSON" "$EVENTS")
  curl "$1" -X POST -H "$2" -H "Content-Type: application/json" -d "$BODY" &>/dev/null
  if [ $? -eq 0 ]; then
    rm "$4"
    printf "$FORMAT" "$4" "true" "true"
  else
    printf "$FORMAT" "$4" "false" "false"
  fi
}
if [[ $1 ]]; then
  IFS=, read -ra PARAM <<< $1
  for i in ${PARAM[@]}; do
    IFS=, read -ra PAIR <<< "$(echo $i | sed -rn 's/"(.*)":"(.*)"/\1,\2/p' | sed 's/{//; s/}//')"
    eval "${PAIR[0]}"="${PAIR[1]}"
  done
fi
if [ ! "$Cloud" ]; then
  echo "Missing 'Cloud'."
  exit 1
fi
if [ ! "$Token" ]; then
  echo "Missing 'Token'."
  exit 1
fi
if [[ ! "$Cloud" =~ "/$" ]]; then
  Cloud+="/"
fi
URL=$Cloud"api/v1/ingest/humio-structured/"
AUTH="Authorization: Bearer "$Token
TAGS='"script":"send_log.sh",'
if [ -f "/opt/CrowdStrike/falconctl" ]; then
  CID=$(/opt/CrowdStrike/falconctl -g --cid | sed 's/^cid="//; s/".$//')
  AID=$(/opt/CrowdStrike/falconctl -g --aid | sed 's/^aid="//; s/".$//')
  TAGS+='"cid":"'$CID'","aid":"'$AID'"'
else
  TAGS+='"host":"'$HOSTNAME'"'
fi
if [[ ! "$File" ]]; then
  for i in /opt/CrowdStrike/RTR/*.json; do
    if [ -f $i ]; then
      send "$URL" "$AUTH" "$TAGS" "$i"
    fi
  done
 elif [[ -f "$File" ]]; then
    send "$URL" "$AUTH" "$TAGS" "$File"
fi