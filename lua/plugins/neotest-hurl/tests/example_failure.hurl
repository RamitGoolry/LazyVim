# Deliberate failure example: expects a 404 while the endpoint returns 200.

GET https://httpbun.org/status/404
HTTP/1.1 200
