API=$( terraform show -json | jq '.values.outputs.api.value' -r )

curl -d @samples/sample-webhook-payload-approved.json  ${API}/clip  -H "Content-Type: application/json"
curl -d @samples/sample-webhook-payload-canceled.json  ${API}/clip  -H "Content-Type: application/json"
curl -d @samples/sample-webhook-payload-declined.json  ${API}/clip  -H "Content-Type: application/json"
