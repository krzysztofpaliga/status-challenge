# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest2
import httpclient, json, strutils, os

proc getUrl1(path: string): string =
  return "http://172.18.0.2:21161" & path

proc getUrl2(path: string): string =
  return "http://172.18.0.3:21161" & path

suite "Test Suite 2: Inter-Node Communication":
  test "verify autoconnection":
    let client = newHttpClient()
    var parsedJson: JsonNode
    while true:
      let response = client.getContent(getUrl1("/admin/v1/peers"))
      parsedJson = parseJson(response)
      if parsedJson.len > 0:
        break
      sleep(3000)

    assert parsedJson[0]["multiaddr"].getStr().contains("172.18.0.3")

test "confirm message publication to a subscribed topic":
    # Subscribe to a topic
    let topic = "/my-app/2/chatroom-1/proto"
    let client = newHttpClient()
    client.headers = newHttpHeaders({"Accept": "text/plain", "Content-Type": "application/json"})

    var data = $[topic]
    let subscriptionResponse = client.post(getUrl2("/relay/v1/auto/subscriptions"), body = data)

    assert subscriptionResponse.status == "200 OK"
    assert subscriptionResponse.body == "OK"

    # Publish a message
    let payload = "UmVsYXkgd29ya3MhIQ=="
    let jsonString =  "{\"payload\":\"" & payload & "\", \"contentTopic\":\"" & topic & "\",\"timestamp\":0}"

    let publishResponse = client.post(getUrl1("/relay/v1/auto/messages"), body = jsonString)
    assert subscriptionResponse.status == "200 OK"
    assert subscriptionResponse.body == "OK"

    # Confirm message publication
    let confirmationResponse = client.getContent(getUrl2("/relay/v1/auto/messages/%2Fmy-app%2F2%2Fchatroom-1%2Fproto"))
    let parsedJson = parseJson(confirmationResponse)
    let receivedPayload = parsedJson[0]["payload"].getStr()
    let receivedTopic = parsedJson[0]["contentTopic"].getStr()

    assert receivedPayload == payload
    assert receivedTopic == topic