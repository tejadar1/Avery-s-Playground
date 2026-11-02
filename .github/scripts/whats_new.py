"""Sets a TestFlight build's "What to Test" text from WhatsNew.txt, through the App Store Connect API.

Waits for the uploaded build to show up (a few minutes after upload), then adds or updates its English notes.
Env: KEY_ID, ISSUER_ID, KEY_PATH (the .p8), BUNDLE_ID, BUILD_NUMBER.
"""
import json, os, time, urllib.request, urllib.error
import jwt  # pip install pyjwt cryptography

API = "https://api.appstoreconnect.apple.com/v1"
key = open(os.environ["KEY_PATH"]).read()


def call(method, path, body=None):
    now = int(time.time())
    token = jwt.encode({"iss": os.environ["ISSUER_ID"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                       key, algorithm="ES256", headers={"kid": os.environ["KEY_ID"], "typ": "JWT"})
    request = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None,
                                     headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SystemExit(f"{method} {path}: {error.code} {error.read().decode()}")


notes = open("WhatsNew.txt").read().strip()[:4000]
app = call("GET", f"/apps?filter[bundleId]={os.environ['BUNDLE_ID']}")["data"][0]["id"]
for _ in range(60):  # up to 30 minutes
    builds = call("GET", f"/builds?filter[app]={app}&filter[version]={os.environ['BUILD_NUMBER']}")["data"]
    if builds:
        break
    print("Waiting for the build to reach App Store Connect...")
    time.sleep(30)
else:
    raise SystemExit("The build didn't show up in App Store Connect, so no notes were set.")

build = builds[0]["id"]
english = [l for l in call("GET", f"/builds/{build}/betaBuildLocalizations")["data"] if l["attributes"]["locale"] == "en-US"]
if english:
    call("PATCH", f"/betaBuildLocalizations/{english[0]['id']}",
         {"data": {"type": "betaBuildLocalizations", "id": english[0]["id"], "attributes": {"whatsNew": notes}}})
else:
    call("POST", "/betaBuildLocalizations",
         {"data": {"type": "betaBuildLocalizations", "attributes": {"locale": "en-US", "whatsNew": notes},
                   "relationships": {"build": {"data": {"type": "builds", "id": build}}}}})
print("What to Test:\n" + notes)
