# Deliberate failure example: expects a 404 while the endpoint returns 200.

GET https://httpbin.org/status/404
HTTP/2 200
