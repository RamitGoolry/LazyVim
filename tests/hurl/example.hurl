# Example Hurl suite exercising two HTTP GET requests.

GET https://httpbin.org/status/200
HTTP/2 200

GET https://httpbin.org/get
HTTP/2 200
[Asserts]
jsonpath "$.url" == "https://httpbin.org/get"
