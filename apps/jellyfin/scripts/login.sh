#!/bin/bash
# ENV VARS (required):
#   BODY  — the full JSON body, e.g. {"Username":"a","Pw":"..."}
#   KEY   — the value to replace Pw with

set -euo pipefail

python3 -c "
import json, os
body = json.loads(os.environ['BODY'])
body['Pw'] = os.environ['KEY']
print(json.dumps(body, separators=(',', ':')))
"